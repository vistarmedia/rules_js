const jsdom = require("jsdom");
const globalJsdom = require("global-jsdom");
const sinon = require("sinon");

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
  beforeEach() {
    if (!global.Date.isFake) {
      this.isFakeTimer = true;
      this.clock = sinon.useFakeTimers({
        shouldAdvanceTime: true,
      });
      const restore = this.clock.restore;
      this.clock.restore = () => {
        this.isFakeTimer = false;
        restore();
      };
    }
  },
  afterEach() {
    if (this.isFakeTimer) {
      this.clock.restore();
    }
  },
  async afterAll() {
    if (this.isFakeTimer) {
      await this.clock.runAllAsync();
    }
    cleanup();
  },
};
