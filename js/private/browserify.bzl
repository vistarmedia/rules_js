load('@io_bazel_rules_js//js/private:rules.bzl',
  'js_binary',
  'node_attr')


def _browserify_impl(ctx):

  entry = ctx.attr.entrypoint.main.short_path.replace('.js', '')

  arguments = [
    '--ignore-transform', 'envify',
    '--outfile',  ctx.outputs.js.path,
    '--entry', './node_modules/' + entry,
  ]

  for t in ctx.attr.transforms:
    arguments.append('--global-transform=' + t)

  if ctx.attr.source_maps:
    arguments.append('--debug')

  ctx.action(
    executable = ctx.executable.bundler,
    arguments  = arguments,
    inputs     = ctx.files.bundler + ctx.files._node,
    outputs    = [ctx.outputs.js],
    mnemonic   = 'Browserify',
    env        = ctx.attr.env,
  )

  return struct(
    files = depset([ctx.outputs.js]),
  )


def _uglify_impl(ctx):

  arguments = [
    '-o', ctx.outputs.js.path,
    ctx.file.src.path,
  ]

  ctx.action(
    executable = ctx.executable._uglify,
    arguments  = arguments,
    inputs     = ctx.files.src + ctx.files._node,
    outputs    = [ctx.outputs.js],
    mnemonic   = 'Uglify',
  )

  return struct(
    files = depset([ctx.outputs.js])
  )


_browserify = rule(
  _browserify_impl,

  attrs = {
    'entrypoint': attr.label(providers=['main']),

    'bundler': attr.label(
      executable = True,
      providers = ['main'],
      cfg = 'host'),

    'env': attr.string_dict(default={}),

    'transforms': attr.string_list(),

    'source_maps': attr.bool(default=False),

    '_node': node_attr,
  },

  outputs = {
    'js': '%{name}.js',
  },
)


_uglify = rule(
  _uglify_impl,

  attrs = {
    'src':  attr.label(single_file=True),

    '_uglify': attr.label(
      default = Label('@io_bazel_rules_js//js/toolchain:uglify'),
      executable = True,
      cfg = 'host'),

    '_node': node_attr,
  },

  outputs = {
    'js': '%{name}.js',
  },
)

def js_bundle(name, bin, minified=False, **kwargs):
  """
  First create a binary "builder" target that contains the `js_binary` source
  and the browserify libraries. Then invoke that target with the necessary
  parameters. If `minified` is specified, it will make another target which
  calls uglify on this source.
  """
  bundler = name + '.bundler'

  js_binary(
    name = bundler,
    src  = '@io_bazel_rules_js//js/toolchain:browserify.js',
    deps = [bin] + [
      '@browserify//:lib',
      '@loose.envify//:lib',
      '@uglifyjs//:lib',
    ],
  )

  if minified:
    browserified = name + '.browserified'
    _browserify(
      name       = browserified,
      entrypoint = bin,
      bundler    = bundler,
      **kwargs)

    _uglify(
      name       = name,
      src        = browserified,
      tags       = kwargs.get('tags', []),
      visibility = kwargs.get('visibility', []))

  else:
    _browserify(
      name       = name,
      entrypoint = bin,
      bundler    = bundler,
      **kwargs)
