const { expect } = require("chai");
const { parseScript } = require("meriyah");
const { spy } = require("sinon");

const { Scope } = require("./scope");
const { visit } = require("./visitor");

class TestLogger {
  error() {}
}

describe("unused identifier finder", () => {
  let ast;
  let logger;
  let scope;

  beforeEach(() => {
    logger = new TestLogger();
    scope = new Scope(undefined, logger);
    scope.declareGlobals([
      "require",
      "console",

      // test globals
      "it",
      "beforeEach",
      "context",
      "describe",
    ]);
  });

  context("when provided with ast without unused variables", () => {
    beforeEach(() => {
      ast = parseScript(
        `
          (function() {
            var ApprovalRecord;
            ApprovalRecord = require("./models");

            console.log(ApprovalRecord())
          }).call(this);
      `,
        { loc: true }
      );
    });

    it("should not log errors", () => {
      logger.error = spy();
      visit(ast, scope);
      scope.check();
      expect(logger.error.callCount).to.equal(0);
    });
  });

  context("when provided with ast with an unused import", () => {
    beforeEach(() => {
      ast = parseScript(
        `
          (function() {
            var List;
            var UnusedRecord;
            var ApprovalRecord;
            ApprovalRecord = require("./models");
            UnusedRecord = require("./unused");
            List = require('immutable');


             describe('', function() {
               return context('', function(){
                 beforeEach(function() {

                 });
                 return it('', function() {
                   s = {
                    t: List([ApprovalRecord()])
                   }
                 });
               });
             });
          }).call(this);
      `,
        { loc: true }
      );
    });

    it("should log errors", () => {
      logger.error = spy();
      visit(ast, scope);
      scope.check();
      expect(logger.error.callCount).to.equal(1);
      expect(logger.error.getCall(0).args[0]).to.have.string("UnusedRecord");
    });
  });

  context("when member expression is computed", () => {
    beforeEach(() => {
      ast = parseScript(
        `
          var TargetOption, options;
          TargetOption = require('TargetOption');
          options = {};

          function setOptions() {
            options[TargetOption.DMA.name] = {};
          }

          setOptions();
        `,
        { loc: true }
      );
    });

    it("should read the identifier", () => {
      logger.error = spy();
      visit(ast, scope);
      scope.check();
      expect(logger.error.callCount).to.equal(0);
    });
  });

  context("when `arguments` keyword is used in functions", () => {
    beforeEach(() => {
      ast = parseScript(
        `
          var myObj = {
            f: function() { // FunctionExpression
              console.log(arguments);
            }
          }

          function hello(obj) { // FunctionDeclaration

            console.log(arguments);
            console.log(obj)
          }
          hello(myObj);
        `,
        { loc: true }
      );
    });

    it("should not mark them as warnings", () => {
      logger.warn = spy();
      visit(ast, scope);
      scope.check();
      expect(logger.warn.callCount).to.equal(0);
    });
  });

  context("when unused variables exist", () => {
    beforeEach(() => {
      ast = parseScript(
        `
          var unusedVar = "unused";
          var param2 = "outerscope_param2";

          function hello(_, param2) {

            var shouldReturn = true;
            var creatives;
            return shouldReturn ? creatives.map() : null;
          }
        `,
        { loc: true }
      );
    });

    it("should log to warnings", () => {
      logger.warn = spy();
      visit(ast, scope);
      scope.check();
      expect(logger.warn.callCount).to.equal(4);
      expect(logger.warn.getCall(0).args[0]).to.have.string("param2");
      expect(logger.warn.getCall(1).args[0]).to.have.string("unusedVar");
      expect(logger.warn.getCall(2).args[0]).to.have.string("param2");
      expect(logger.warn.getCall(3).args[0]).to.have.string("hello");
    });
  });

  context("when undefined variable is referenced", () => {
    beforeEach(() => {
      ast = parseScript("console.log(foo)", { loc: true });
    });

    it("should log to warnings", () => {
      logger.warn = spy();
      visit(ast, scope);
      scope.check();
      expect(logger.warn.callCount).to.equal(1);
      expect(logger.warn.getCall(0).args[0]).to.equal("foo is undefined");
    });
  });
});
