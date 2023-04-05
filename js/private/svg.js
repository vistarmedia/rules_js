//Allow mocha to handle svg file imports in tests
require.extensions[".svg"] = (_module, _filename) => {
  return "svg image import";
};
