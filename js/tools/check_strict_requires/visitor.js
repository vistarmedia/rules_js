function isRequired(ast) {
  return (
    (ast.type == "CallExpression" && ast.callee.name == "require") ||
    (ast.type == "MemberExpression" &&
      ast.object.type == "CallExpression" &&
      ast.object.callee.name == "require")
  );
}

function isArray(thing) {
  return toString.call(thing) === "[object Array]";
}

function visit(ast, scope) {
  switch (ast.type) {
    case "Program":
      scope.child((child) => {
        visitAll(ast.body, child);
      });
      break;

    case "ExpressionStatement":
      visit(ast.expression, scope);
      break;

    case "CallExpression":
      visit(ast.callee, scope);
      visitAll(ast.arguments, scope);
      break;

    case "MemberExpression":
      visit(ast.object, scope);
      if (ast.computed) {
        visit(ast.property, scope);
      }
      break;

    case "FunctionExpression":
      scope.child((child) => {
        child.declareGlobals(["arguments"]);
        ast.params.forEach((param) => {
          child.declare(param.name, param.loc);
        });
        if (isArray(ast.body)) {
          visitAll(ast.body);
        } else {
          visit(ast.body, child);
        }
      });
      break;

    case "BlockStatement":
      scope.child((child) => {
        visitAll(ast.body, child);
      });
      break;

    case "VariableDeclaration":
      visitAll(ast.declarations, scope);
      break;

    case "AssignmentExpression":
      ast.left.isAssignment = true;
      ast.left.isRequired = isRequired(ast.right);
      visit(ast.left, scope);
      visit(ast.right, scope);
      break;

    case "LogicalExpression":
    case "BinaryExpression":
      visit(ast.left, scope);
      visit(ast.right, scope);
      break;

    case "ObjectExpression":
      visitAll(ast.properties, scope);
      break;

    case "Property":
      if (ast.computed) {
        visit(ast.key, scope);
      }
      visit(ast.value, scope);
      break;

    case "ReturnStatement":
      if (ast.argument != null) {
        visit(ast.argument, scope);
      }
      break;

    case "IfStatement":
      visit(ast.test, scope);
      visit(ast.consequent, scope);
      if (ast.alternate != null) {
        visit(ast.alternate, scope);
      }
      break;

    case "ForStatement":
      visit(ast.init, scope);
      visit(ast.body, scope);
      visit(ast.test, scope);
      visit(ast.update, scope);
      break;

    case "ForInStatement":
      visit(ast.body, scope);
      visit(ast.left, scope);
      visit(ast.right, scope);
      break;

    case "UpdateExpression":
      visit(ast.argument, scope);
      break;

    case "ArrayExpression":
      visitAll(ast.elements, scope);
      break;

    case "NewExpression":
      visit(ast.callee, scope);
      visitAll(ast.arguments, scope);
      break;

    case "FunctionDeclaration":
      scope.declare(ast.id.name, ast.loc);
      scope.child((child) => {
        child.declareGlobals(["arguments"]);
        ast.params.forEach((param) => child.declare(param.name, param.loc));
        visit(ast.body, child);
      });
      break;

    case "ConditionalExpression":
      visit(ast.test, scope);
      visit(ast.consequent, scope);
      visit(ast.alternate, scope);
      break;

    case "Identifier":
      if (!ast.isAssignment) {
        // coffeescript is compiled in a way where all variables are first declared,
        // and then assigned. If we're at point where we are assigning a value to
        // a declared variable, we don't want to add to the "readCount" of the identifier
        scope.read(ast.name, ast.loc);
      } else if (ast.isRequired) {
        scope.readImport(ast.name);
      }
      break;

    case "VariableDeclarator":
      if (ast.init != null) {
        visit(ast.init, scope);
      }
      scope.declare(ast.id.name, ast.loc);
      break;

    case "SwitchStatement":
      visit(ast.discriminant, scope);
      visitAll(ast.cases, scope);
      break;

    case "SwitchCase":
      if (ast.test != null) {
        // when not "default" case
        visit(ast.test, scope);
      }
      visitAll(ast.consequent, scope);
      break;

    case "SequenceExpression":
      visitAll(ast.expressions, scope);
      break;

    case "UnaryExpression":
    case "ThrowStatement":
      visit(ast.argument, scope);
      break;

    case "WhileStatement":
      visit(ast.test, scope);
      visit(ast.body, scope);
      break;

    case "BreakStatement":
    case "Literal":
    case "ThisExpression":
      break;

    default:
      console.log(ast);
      throw Error("cannot handle type: " + ast.type);
  }
}

function visitAll(asts, scope) {
  asts.forEach((ast) => visit(ast, scope));
}

module.exports = {
  visit,
};
