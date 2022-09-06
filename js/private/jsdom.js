const jsdom = require("jsdom");
const globalJsdom = require("global-jsdom");

const cookieJar = new jsdom.CookieJar(undefined, {
  allowSpecialUseDomain: true,
  rejectPublicSuffixes: false,
});

const cleanup = globalJsdom("", {
  pretendToBeVisual: true,
  url: "http://localhost.local:3000",
  cookieJar,
});

module.exports.mochaHooks = {
  afterAll() {
    cleanup();
  },
};
