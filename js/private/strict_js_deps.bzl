load('@com_vistarmedia_rules_js//js/private:rules.bzl', 'js_lib_providers')


def _strict_js_deps(ctx):
  inputs = ctx.attr.src.direct_cdeps + [ctx.attr.src.jsar, ctx.executable._node]

  paths = struct(
    src_jsar = ctx.attr.src.jsar.path,
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

def _strict_js_src_deps(ctx):
  jsars = [jsar.cjsar  for jsar in ctx.attr.deps]

  inputs = jsars + ctx.files.srcs + [ctx.executable._node]

  paths = struct(
    srcs = [src.path for src in ctx.files.srcs],
    output = ctx.outputs.ok.path,
    deps = [jsar.path for jsar in jsars],
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
  doc = """
Generate a target that will only be created if the sources of this target:
  * Only import things declared in its `deps` -- transitive dependencies are not
    allowed
  * Declare a "dep" that is not required by any of its source files
""",
  attrs = {
    'src': attr.label(providers=js_lib_providers),

    '_check_strict_deps': attr.label(
      default = Label('@com_vistarmedia_rules_js//js/tools/check_strict_deps:check_strict_deps'),
      executable = True,
      cfg = 'host'),

    '_node':  attr.label(
      default = Label('@com_vistarmedia_rules_js//js/toolchain:node'),
      cfg = 'host',
      executable = True,
      allow_single_file = True),
  },
  outputs = {
    'ok': '%{name}.ok',
  }
)

strict_js_src_deps = rule(
  _strict_js_src_deps,
  doc = """
Generate a target that will only be created if the imports defined in the given
source files:
      * Only import things from the given `deps`
      * Don't have any `deps` that aren't used.
""",
  attrs = {
    'srcs': attr.label_list(allow_files=True),
    'deps': attr.label_list(providers=js_lib_providers),

    '_check_strict_deps': attr.label(
      default = Label('@com_vistarmedia_rules_js//js/tools/check_strict_deps:check_strict_deps'),
      executable = True,
      cfg = 'host'),

    '_node':  attr.label(
      default = Label('@com_vistarmedia_rules_js//js/toolchain:node'),
      cfg = 'host',
      executable = True,
      allow_single_file = True),
  },
  outputs = {
    'ok': '%{name}.ok',
  }
)
