const colorCyan = (str) => `\x1b[36m${str}\x1b[0m`;
const colorRed = (str) => `\x1b[31m${str}\x1b[0m`;
const colorYellow = (str) => `\x1b[43m${str}\x1b[0m`;

class Logger {
  constructor(name, src) {
    this.name = name;
    this.src = src;
    this.lines = src.split("\n");

    this.warnings = [];
    this.errors = [];
  }

  formatMsg(msg, loc) {
    const { start, end } = loc;

    // Prefix file/line in cyan
    const prefix = colorCyan(`${this.name}:${start.line}`);
    let errorMsg = `${prefix} ${msg}`;

    let srcMsg = "";
    for (let i = start.line - 1; i < end.line; i++) {
      const lineNo = i + 1;
      let line = this.lines[i];

      // If the ending is on this line, insert a color-end at that position. Do
      // the ending first to preserve the index of the beginning, which may also
      // be on this line
      if (lineNo == end.line) {
        line = line.slice(0, end.column) + "\x1b[0m" + line.slice(end.column);
      }
      // Insert "start red" when the error begins
      if (lineNo == start.line) {
        line =
          line.slice(0, start.column) + "\x1b[31m" + line.slice(start.column);
      }
      errorMsg = `${errorMsg} \n ${line}`;
    }
    return errorMsg;
  }

  getErrors() {
    return this.errors;
  }

  getWarnings() {
    return this.warnings;
  }

  error(msg, loc) {
    this.errors.push(this.formatMsg(msg, loc));
  }

  warn(msg, loc) {
    this.warnings.push(this.formatMsg(msg, loc));
  }
}

module.exports = {
  Logger,
  colorCyan,
  colorRed,
  colorYellow,
};
