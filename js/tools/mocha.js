require("mocha/bin/mocha");

//Allow mocha to handle svg file imports in tests
require.extensions[".svg"] = () => "svg image import";
