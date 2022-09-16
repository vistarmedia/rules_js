let consoleWarn = console.warn;
let consoleError = console.error;

module.exports.mochaHooks = {
  beforeAll() {
    console.warn = (msg, ...args) => {
      throw new Error(msg, ...args);
    };
    console.error = (msg, ...args) => {
      console.log(msg, ...args);
      throw new Error(msg, ...args);
    };
  },
  afterAll() {
    console.warn = consoleWarn;
    console.error = consoleError;
  },
};
