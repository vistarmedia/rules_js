load('@io_bazel_rules_js//js/private:rules.bzl',
  'build_jsar',
  'node_driver',
  'transitive_jsars',
  'jsar_attr',
  'node_attr',
  'js_dep_attr')


def _js_test_impl(ctx):
  deps = ctx.attr.deps + [
    ctx.attr._mocha,
    ctx.attr._source_map_support,
  ]

  arguments = [
    'node_modules/mocha/bin/mocha',
    '--require=source-map-support/register',
  ]

  arguments += \
    ['--require=node_modules/%s' % src.short_path for src in ctx.files.requires]

  if ctx.attr.reporter:
    reporter = ctx.attr.reporter
    deps += [reporter]
    arguments += ['--reporter=' + reporter.label.package]

  arguments += ['node_modules/%s' % src.short_path for src in ctx.files.srcs]

  jsar = build_jsar(ctx,
    files   = ctx.files.srcs + ctx.files.requires,
    jsars   = transitive_jsars(deps),
    output  = ctx.outputs.jsar,
    package = None,
  )

  node_driver(ctx,
    output    = ctx.outputs.executable,
    jsar      = jsar,
    node      = ctx.executable._node,
    arguments = arguments,
  )

  runfiles = ctx.runfiles(
    files = [
      ctx.executable._jsar,
      ctx.executable._node,
      jsar,
    ] + ctx.files.data,
    collect_default  = True,
  )

  return struct(
    files    = depset([jsar, ctx.outputs.executable]),
    runfiles = runfiles,
  )


js_test = rule(
  _js_test_impl,
  test = True,
  attrs = {
    'srcs':                attr.label_list(allow_files=True),
    'deps':                js_dep_attr,
    'data':                attr.label_list(allow_files=True, cfg='data'),
    'requires':            attr.label_list(allow_files=True),
    'reporter':            attr.label(),
    '_node':               node_attr,
    '_jsar':               jsar_attr,
    '_mocha':              attr.label(default=Label('@mocha//:lib')),
    '_source_map_support': attr.label(
                             default=Label('@source.map.support//:lib')),
  },
  outputs = {
    'jsar': '%{name}.jsar',
  },
)
