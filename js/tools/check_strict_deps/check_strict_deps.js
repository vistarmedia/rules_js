const fs = require("fs");
const { promisify } = require("util");

const { unbundle } = require("io_bazel_rules_js/js/tools/jsar/jsar");

const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);

/**
 * Code will sometimes invoke properties of a required module to walk a
 * dependency tree. This value will return itself for every property called.
 * This could potentially yield bad results if there is a programatic require
 * statement.
 */
const moduleProxy = new Proxy(() => {}, {
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

  new Function("require", "module", "window", "describe", src)(
    captureImport, // require
    moduleProxy, // module
    moduleProxy, // window
    moduleProxy // describe, for mocha tests
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
    `File '${file}' imports "${literalImpt}" which could not be ` +
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
  // Step 1: Read all our deps
  let deps = {};
  for (let depName of paths.deps) {
    const dep = await unbundle(await readFile(depName));
    deps[depName] = {
      files: Object.keys(dep),
      imported_by: []
    };
  }

  // Step 2: Figure out all our imports. Then can either be given to us by a
  // `src_jsar` path parameter, or a list in of `srcs` paths.
  const srcFiles = paths.src_jsar
    ? unbundle(await readFile(paths.src_jsar))
    : readSources(paths.srcs);
  const imports = await getImports(await srcFiles);

  // Step 3: Resolve the imports against the deps
  for (let importer of imports) {
    for (let impt of importer.imports) {
      resolve(importer.file, impt, deps);
    }
  }

  for (let jsar in deps) {
    const { imported_by } = deps[jsar];
    if (imported_by.length == 0) {
      throw Error(`${jsar} declared as dep, but not used`);
    }
  }

  // Everything checks out! Write the dep/import datastructure to the "ok" file
  await writeFile(paths.output, JSON.stringify(deps, null, 2));
}

main(JSON.parse(process.argv[2])).catch(err => {
  console.error(err.stack);
  process.exit(1);
});
