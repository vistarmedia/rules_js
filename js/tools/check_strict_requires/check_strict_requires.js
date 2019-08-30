const fs = require("fs");
const { parseScript } = require("meriyah");
const { promisify } = require("util");

const { unbundle } = require("com_vistarmedia_rules_js/js/tools/jsar/jsar");

const { Logger } = require("./logger");
const { Scope } = require("./scope");
const { visit } = require("./visitor");

const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);

/**
 * Parses the file, checks for unused imports, variables, and usages of
 * undefined variables and returns an Object with the errors and warnings
 * @returns an Object in the shape:
 *    {errors: Array<string>, warnings: Array<string>}
 */
async function checkFile(fileName, src) {
  const ast = parseScript(src, { loc: true });

  const logger = new Logger(fileName, src);
  const scope = new Scope(undefined, logger);
  scope.declareGlobals([
    "Array",
    "Blob",
    "Date",
    "FileReader",
    "JSON",
    "Math",
    "Number",
    "Object",
    "Promise",
    "RegExp",
    "console",
    "document",
    "ga", // TODO: Should be acquired from window
    "history", // TODO: Should be acquired from window
    "isNaN",
    "location",
    "module",
    "parseFloat",
    "parseInt",
    "process",
    "require",
    "window",

    // test globals
    "it",
    "beforeEach",
    "context",
    "describe"
  ]);
  visit(ast, scope);
  scope.check();
  return { errors: logger.getErrors(), warnings: logger.getWarnings() };
}

async function readSources(srcPaths) {
  const srcs = await Promise.all(srcPaths.map(srcPath => readFile(srcPath)));
  return srcs.reduce((acc, src, idx) => {
    return Object.assign({}, acc, { [srcPaths[idx]]: src.toString() });
  }, {});
}

async function main(paths) {
  const srcByFileName = paths.src_jsar
    ? await unbundle(await readFile(paths.src_jsar))
    : await readSources(paths.srcs);

  for (fileName in srcByFileName) {
    // We could try doing this in parallel, but we sacrifice the reproducibility
    // of the failures and the errors not being the same on each run
    const { errors, warnings } = await checkFile(
      fileName,
      srcByFileName[fileName]
    );
    if (errors.length !== 0) {
      throw new Error(errors.join("\n"));
    }
    if (warnings.length !== 0) {
      console.warn(warnings.join("\n"));
    }
  }

  await writeFile(paths.output, "ok");
}

module.exports = {
  checkStrictRequires: main
};
