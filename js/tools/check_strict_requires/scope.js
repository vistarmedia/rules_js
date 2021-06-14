const { colorRed } = require("./logger");
const { colorYellow } = require("./logger");

class Identifier {
  constructor(loc) {
    this.numUses = 0;
    this.imported = false;
    this.loc = loc;
  }

  use() {
    this.numUses++;
  }

  isUsed() {
    return this.numUses > 0;
  }

  isImported() {
    return this.imported;
  }
}

IGNORED_UNUSED_VARIABLES = ["_", "__"];

class Scope {
  constructor(parent, logger, depth = 0) {
    this.parent = parent;
    this.logger = logger;

    this.identifiers = {};
    this.depth = depth;
  }

  child(func) {
    const scope = new Scope(this, this.logger, this.depth + 1);
    func(scope);
    scope.check();
  }

  check() {
    Object.keys(this.identifiers).forEach((name) => {
      const identifier = this.identifiers[name];
      if (!identifier.isUsed()) {
        if (identifier.isImported()) {
          this.logger.error(`Unused import ${colorRed(name)}`, identifier.loc);
        } else {
          if (!IGNORED_UNUSED_VARIABLES.includes(name)) {
            this.logger.warn(
              `Unused variable ${colorYellow(name)}`,
              identifier.loc
            );
          }
        }
      }
    });
  }

  declareGlobals(names) {
    names.forEach((name) => {
      this.declare(name, {});
      this.read(name);
    });
  }

  declare(name, loc) {
    if (this.identifiers[name] != null) {
      this.logger.warn(`cannot redeclare ${name}`, loc);
      return;
    }
    this.identifiers[name] = new Identifier(loc);
  }

  read(name, loc) {
    const identifier = this.identifiers[name];
    if (identifier != null) {
      identifier.use();
    } else if (this.parent) {
      this.parent.read(name, loc);
    } else {
      this.logger.warn(`${name} is undefined`, loc);
    }
  }

  readImport(name) {
    const identifier = this.identifiers[name];
    identifier.imported = true;
  }
}

module.exports = {
  Scope,
};
