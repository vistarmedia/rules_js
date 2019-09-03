const fs = require("fs");
const { promisify } = require("util");

const { unbundle } = require("com_vistarmedia_rules_js/js/tools/jsar/jsar");
const {
  checkStrictRequires
} = require("com_vistarmedia_rules_js/js/tools/check_strict_requires/check_strict_requires");

const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);

/**
 * Code will sometimes invoke properties of a required module to walk a
 * dependency tree. This value will return itself for every property called.
 * This could potentially yield bad results if there is a programatic require
 * statement.
 *
 * The `_inner` value needs to be a function so code calling `new {import}()`
 * will execute.
 */
function _inner() {}
const moduleProxy = new Proxy(_inner, {
  construct(target, args) {
    return moduleProxy;
  },
  get(target, name, receiver) {
    return moduleProxy;
  },
  apply(target, thisArg, argList) {
    return moduleProxy;
  }
});

async function getFileImports(src) {
  let imports = [];
  const captureImport = impt => {
    if (imports.indexOf(impt) < 0) {
      imports.push(impt);
    }
    return moduleProxy;
  };

  const proxiedKeywords = [
    "afterEach",
    "beforeEach",
    "describe",
    "module",
    "window"
  ];
  const proxies = new Array(proxiedKeywords.length).fill(moduleProxy);

  new Function("require", ...proxiedKeywords, src)(
    captureImport, // require
    ...proxies
  );

  return imports;
}

async function getImports(jsar) {
  let imports = [];

  for (let file in jsar) {
    const fileImports = await getFileImports(jsar[file]);
    imports.push({ file, imports: fileImports });
  }

  return imports;
}

const colorRed = str => `\x1b[31m${str}\x1b[0m`;

function resolve(file, literalImpt, deps) {
  // Don't look at relative imports
  if (literalImpt.startsWith(".")) {
    return;
  }

  const impt = literalImpt.startsWith("/") ? literalImpt : `/${literalImpt}`;

  const search = [
    `${impt}`,
    `${impt}.js`,
    `${impt}.d.ts`,
    `${impt}.json`,
    `${impt}/index.js`,
    `${impt}/index.d.ts`,
    `${impt}/index.json`,
    `${impt}/package.json`
  ];

  for (let jsar in deps) {
    const files = deps[jsar];
    for (let file of files.files) {
      if (search.indexOf(file) >= 0) {
        deps[jsar].imported_by.push(file);
        return;
      }
    }
  }

  throw Error(
    `File '${file}' imports "${colorRed(literalImpt)}" which could not be ` +
      `resolved as a direct dependency`
  );
}

async function readSources(srcPaths) {
  let sources = {};
  for (let srcPath of srcPaths) {
    sources[srcPath] = (await readFile(srcPath)).toString();
  }
  return sources;
}

async function main(paths) {
  // Step 1: Check that required imports are used
  await checkStrictRequires(paths);

  // Step 2: Read all our deps
  let deps = {};
  for (let depName of paths.deps) {
    const dep = await unbundle(await readFile(depName));
    deps[depName] = {
      files: Object.keys(dep),
      imported_by: []
    };
  }

  // Step 3: Figure out all our imports. Then can either be given to us by a
  // `src_jsar` path parameter, or a list in of `srcs` paths.
  const srcFiles = paths.src_jsar
    ? unbundle(await readFile(paths.src_jsar))
    : readSources(paths.srcs);
  const imports = await getImports(await srcFiles);

  // Step 4: Resolve the imports against the deps
  for (let importer of imports) {
    for (let impt of importer.imports) {
      resolve(importer.file, impt, deps);
    }
  }

  for (let jsar in deps) {
    if (paths.ignored_deps.indexOf(jsar) >= 0) {
      continue;
    }

    const { imported_by } = deps[jsar];
    if (imported_by.length == 0) {
      throw Error(`${colorRed(jsar)} declared as dep, but not used`);
    }
  }

  // Everything checks out! Write the dep/import datastructure to the "ok" file
  await writeFile(paths.output, JSON.stringify(deps, null, 2));
}

main(JSON.parse(process.argv[2])).catch(err => {
  console.error(err.stack);
  process.exit(1);
});
