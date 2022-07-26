const jsdom = require("jsdom");
const globalJsdom = require("global-jsdom");

const cookieJar = new jsdom.CookieJar(undefined, {
  allowSpecialUseDomain: true,
  rejectPublicSuffixes: false,
});

globalJsdom("", {
  pretendToBeVisual: true,
  url: "http://localhost.local:3000",
  cookieJar,
});
