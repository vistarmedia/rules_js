js_type          = FileType(['.js'])
js_dep_providers = ['jsar', 'deps']


def transitive_jsars(deps):
  jsars = depset()
  for dep in deps:
    jsars += dep.deps | [dep.jsar]
  return jsars


def _jsar_impl(ctx):
  tar  = ctx.file.tar
  jsar = ctx.outputs.jsar

  arguments = [
    'fromtarball',
    '-output', jsar.path,
    tar.path,
  ]

  ctx.action(
    executable = ctx.executable._jsar,
    arguments  = arguments,
    inputs     = [tar],
    outputs    = [jsar],
    mnemonic   = 'PackageTarJsar',
  )

  return struct(
    files = depset([jsar]),
    jsar  = jsar,
    deps  = transitive_jsars(ctx.attr.deps),
  )

def _jsar_path(src):
  path = src.short_path
  if path.startswith('../'):
    return path[3:]
  return path


def _build_src_jsar(ctx, srcs, output):
  arguments = [
    'bundle',
    '-output', output.path,
  ] + [
    '%s=/%s' % (s.path, _jsar_path(s)) for s in srcs
  ]

  ctx.action(
    executable = ctx.executable._jsar,
    arguments  = arguments,
    inputs     = list(srcs),
    outputs    = [output],
    mnemonic   = 'PackageSrcJsar',
  )

  return output


def _build_dep_jsar(ctx, deps, output):
  command = ' '.join(
    ['cat'] + [dep.path for dep in deps] + \
    ['>', output.path]
  )

  ctx.action(
    command    = command,
    inputs     = list(deps),
    outputs    = [output],
    mnemonic   = 'PackageDepJsar',
  )

  return output


def build_jsar(ctx, files, jsars, output):
  src_jsar = _build_src_jsar(
    ctx, files, ctx.new_file(ctx.label.name +'.srcJsar'))

  return _build_dep_jsar(ctx, jsars + [src_jsar], output)


def _js_library_impl(ctx):
  jsar = ctx.outputs.jsar
  build_jsar(ctx, ctx.files.srcs, [], jsar)

  ts_defs = depset()
  if ctx.attr.ts_defs:
    ts_defs = ctx.attr.ts_defs.ts_defs

  return struct(
    files   = depset([jsar]),
    jsar    = jsar,
    deps    = transitive_jsars(ctx.attr.deps),
    ts_defs = ts_defs,
  )


def node_driver(ctx, output, jsar, node, arguments=[]):
  safe_args = ["'%s'" % arg for arg in arguments]

  content = [
    '#!/bin/bash -eu',
    'set -o pipefail',

    # Get full path of the script and set it to `$self`. If it isn't absolute,
    # prefix `$PWD` to ensure it is.
    'case "$0" in',
    '/*) self="$0" ;;',
    '*)  self="${PWD}/${0}" ;;',
    'esac',

    # When executing as a binary target, Bazel will place our runfiles in the
    # same name as this script with a '.runfiles' appended. When running as a
    # test, however, it will set the environment variable, $TEST_SRCDIR to the
    # value.
    'runfiles_root="${self}.runfiles"',
    'if [ -v TEST_SRCDIR ]; then',
    '   runfiles_root="$TEST_SRCDIR"',
    'fi',

    'export RUNFILES="${runfiles_root}/%s"' % ctx.workspace_name,

    'if ! [[ -d ./node_modules ]]; then',
    '  mkdir ./node_modules',
    '  trap "{ rm -rf ./node_modules ; }" EXIT',
    'fi',

    '${RUNFILES}/%s unbundle -output ./node_modules "${RUNFILES}/%s"' % (
      ctx.executable._jsar.short_path,
      jsar.short_path),

    'NODEPATH=$PWD {node} {arguments} "$@"'.format(
      node      = node.path,
      arguments = ' '.join(safe_args)
    ),
  ]

  ctx.file_action(
    output     = output,
    content    = '\n'.join(content),
    executable = True,
  )


def _js_binary_impl(ctx):
  jsar = build_jsar(ctx,
    files  = ctx.files.src,
    jsars  = transitive_jsars(ctx.attr.deps),
    output = ctx.outputs.jsar,
  )

  arguments = ['./node_modules/%s' % _jsar_path(ctx.file.src)]

  node_driver(ctx,
    output    = ctx.outputs.executable,
    jsar      = jsar,
    node      = ctx.executable._node,
    arguments = arguments,
  )

  runfiles = ctx.runfiles(
    files = [
      jsar,
      ctx.executable._node,
      ctx.executable._jsar,
    ],
    collect_default = True,
  )

  return struct(
    files    = depset([jsar]),
    runfiles = runfiles,
    jsar     = jsar,
    deps     = depset(),
    main     = ctx.file.src,
  )

# ------------------------------------------------------------------------------

jsar_attr = attr.label(
  default    = Label('@io_bazel_rules_js//js/tools:jsar-bin'),
  cfg        = 'data',
  executable = True)

node_attr = attr.label(
  default     = Label('//js/toolchain:node'),
  cfg         = 'host',
  executable  = True,
  allow_files = True)

js_dep_attr = attr.label_list(providers=js_dep_providers)


jsar = rule(
  _jsar_impl,
  attrs = {
    'tar':   attr.label(
      allow_files = FileType(['.tgz', '.tar.gz']),
      single_file = True,
      mandatory   = True),

    'deps':  js_dep_attr,
    '_jsar': jsar_attr,
  },
  outputs = {
    'jsar': '%{name}.jsar',
  },
)

js_library = rule(
  _js_library_impl,
  attrs = {
    'srcs':    attr.label_list(allow_files=True),
    'deps':    js_dep_attr,
    'ts_defs': attr.label(providers=['ts_defs']),
    '_jsar':   jsar_attr,
  },
  outputs = {
    'jsar': '%{name}.jsar',
  },
)

js_binary = rule(
  _js_binary_impl,
  executable = True,
  attrs = {
    'src':     attr.label(allow_files=True, single_file=True),
    'deps':    js_dep_attr,
    '_jsar':   jsar_attr,
    '_node':   node_attr,
  },
  outputs = {
    'jsar': '%{name}.jsar',
  },
)
