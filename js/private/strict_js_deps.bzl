load('@io_bazel_rules_js//js/private:rules.bzl', 'js_lib_providers')


def _strict_js_deps(ctx):
  inputs = ctx.attr.src.direct_cdeps + \
    [ctx.attr.src.jsar] + \
    [ctx.executable._node]

  paths = struct(
    src = ctx.attr.src.jsar.path,
    output = ctx.outputs.ok.path,
    deps = [dep.path for dep in ctx.attr.src.direct_cdeps],
  )

  ctx.actions.run(
    inputs = inputs,
    outputs = [ctx.outputs.ok],
    arguments = [paths.to_json()],
    executable = ctx.executable._check_strict_deps,
    mnemonic = 'StrictJsDeps',
  )

strict_js_deps = rule(
  _strict_js_deps,
  attrs = {
    'src': attr.label(providers=js_lib_providers),

    '_check_strict_deps': attr.label(
      default = Label('@io_bazel_rules_js//js/tools/check_strict_deps:check_strict_deps'),
      executable = True,
      cfg = 'host'),

    '_node':  attr.label(
      default = Label('@io_bazel_rules_js//js/toolchain:node'),
      cfg = 'host',
      executable = True,
      allow_single_file = True),
  },
  outputs = {
    'ok': '%{name}.ok',
  }
)
