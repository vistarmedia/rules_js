let consoleWarn = console.warn;
let consoleError = console.error;

module.exports.mochaHooks = {
  beforeEach() {
    console.warn = (msg, ...args) => {
      console.log(msg, ...args);
      this.failures++;
      throw Error(msg, ...args);
    };
    console.error = (msg, ...args) => {
      console.log(msg, ...args);
      this.failures++;
      throw Error(msg, ...args);
    };
  },
  afterEach() {
    console.warn = consoleWarn;
    console.error = consoleError;
  },
};
