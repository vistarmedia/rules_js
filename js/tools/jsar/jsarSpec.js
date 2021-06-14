const fs = require("fs");
const path = require("path");
const { promisify } = require("util");

const { expect } = require("chai");

const { bundle } = require("js/tools/jsar/jsar");
const { unbundle } = require("js/tools/jsar/jsar");

const close = promisify(fs.close);
const open = promisify(fs.open);
const readFile = promisify(fs.readFile);
const write = promisify(fs.write);

const validBuffer = Buffer.from(
  "H4sIAAAAAAAC/4TNPQvCMBDG8b2f4rhRSougg30Dd7tI9xKTGyIhKbmLtEi/u4NKcXL/P79n90SPFZYPy6JiqYNzpMUGX1pvaC7ujDkyVof9iokJWKLVgnVG8xSicDGOxH0wyRG0IDFRneV/TFPIRz0d17cDhrRTkUCWieBiWZqhgxaupEzwbjnHqJZm6L6/v32fRN0cbbMtfwEAAP//AQAA//83FsMq4AAAAA==",
  "base64"
);

describe("unbundle", () => {
  context("when I unbundle a valid buffer", () => {
    let files;

    beforeEach((done) => {
      unbundle(validBuffer)
        .then((f) => {
          files = f;
        })
        .then(done)
        .catch(done);
    });

    it("should load the files", () => {
      expect(files).to.deep.equal({
        "/vistar/collection/index.d.ts":
          "export declare type List<T> = ReadonlyArray<T>;\nexport declare type MutableList<T> = Array<T>;\n",
        "/vistar/collection/index.js":
          '"use strict";\nexports.__esModule = true;\n',
      });
    });
  });
});

describe("jsarWriter", () => {
  it("should write a file", async () => {
    const fname = path.join(process.env.TEST_TMPDIR, "test.jsar");

    const file = await open(fname, "w");
    await write(file, bundle("/etc/passwd", "Nice programmings"));
    await write(file, bundle("/etc/shadow", "Hat town"));
    await close(file);

    const jsar = await unbundle(await readFile(fname));
    expect(jsar).to.deep.equal({
      "/etc/passwd": "Nice programmings",
      "/etc/shadow": "Hat town",
    });
  });
});
