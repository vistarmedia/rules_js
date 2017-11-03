# Javascript Rules
This project aims to bring Javascript support to Bazel. Binary targets can be
run with Node, library targets produce concise binary build artifacts.

## Rules
There are two public module rules

    ```python
    load('@io_bazel_rules_js//js:def.bzl',
      'js_binary',
      'js_library')

    js_library(
      name = 'lib',
      srcs = ['lib.js']
    )

    js_binary(
      name = 'bin',
      srcs = ['main.js'],
      deps = [':lib'],
    )
    ```

Note that each `src` passed to a `js_binary` rule will run with a new invocation
of Node, and it will silently ignore any `src` file that doesn't have a `.js`
extension.

Further, there is a WORKSPACE rule to install modules from NPM, optionally
include their typescript definitions. `npm_install` will also take a `sha256`
argument to verify against what's published on NPM as well as a `type_sha256`
for the type declaration.

    ```python
    load('@io_bazel_rules_js//js:def.bzl', 'npm_install')
    npm_install('immutable', version='3.8.1', type_version='3.8.1')
    ```

The resulting library will be available as `@immutable//:lib`.

Because the rule will create your `BUILD` file for you, it needs to include all
specified dependencies. Occasionally, a library will have some functionality you
don't need that pulls in a large number of transitive dependencies. While
unsafe, you can pass `npm_install` a `ignore_deps` list of strings (of the Bazel
dot-style names), and they will not be included as dependencies. This li'l trick
is to be used at your own risk.

## External Dependencies
When using `npm_install`, a module will be created with the source for that NPM
project. For a simply named library (say `react`), other modules are free to
depend on a module named `@react//:lib`. However, the `-` character (and perhaps
others) is not allowed in external names with Bazel, so they will be replaced
with a `.`. For example, `honk-di` would be required in a `BUILD` file as
`@honk.di//:lib`.

These rules will declare dependencies, but they will not resolve them. For
example, if you declare an `npm_install` rule for `@bar//:lib`, which depends on
`@foo//:lib`, Bazel will fail to build citing that it can't find `@foo//:lib`.
You must determine a version and explicitly define it at the `WORKSPACE` level.

When encountering such a resolution error, it's helpful to look at the file
where the error occurred (namely, the `BUILD` file for `@bar//:lib`). This
file will have comments for the all of its dependencies and versions it provided
in its `package.json`. It's fair to say most will be semvar ranges rather than
specific versions, so it's up to you to find the right release.

## Module Resolution
For external modules (installed with `npm_install`), import statements will work
the same as with Node and NPM. `honk-di` will be importable as `honk-di`.

For internal modules, the following convention should be applied:
  * If the file is part of the current target, import it with a relative path.
    For example `require('./widget')`
  * If the file is part of another target, import it with a fully-qualified
    path. So, if working in `//lib/ui/actions` and you need a library from
    `//lib/net/ajax`, use `require('lib/net/ajax')`.

Both presently work in nearly all cases, but the behavior is not guaranteed as
these rules evolve.

## Design
Each build target produces metadata and a binary Javascript archive, or `jsar`.
Each `js_library` emits its own js runtime files as a gzipped tarfile. The path
of the files will be the fully-qualified import path. The metadata is as
follows:

    ```python
    struct(
      jsar = <this library's code>,
      deps = set(<jsar>),
    )
    ```

A `js_binary` target will create a "fat" archive -- its local code, and the code
of all its transitive dependencies. It will also create a runner script which
will extract these files to a local `./node_modules`, invoke each `src` file,
then remove `./node_modules`.

External dependencies created with `npm_install` will use a behind-the-scenes
rule, `jsar` to directly create the tarfile containing the sources with working
directly with `js_library`. This is subject to change.
