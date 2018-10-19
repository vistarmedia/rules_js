js_lib_providers = ['jsar', 'runtime_deps', 'compile_deps']
js_bin_providers = ['jsar', 'runtime_deps']


def runtime_deps(deps):
  """
  Set of transitive jsar files needed to run this target
  """
  jsars = depset()
  for dep in deps:
    jsars += dep.runtime_deps.union([dep.jsar])
  return jsars

def compile_deps(deps):
  """
  Set of transitive jsar files needed to compile this target
  """
  cjsars = depset()
  for dep in deps:
    cjsars += dep.compile_deps.union([dep.cjsar])
  return cjsars


def _jsar_impl(ctx):
  """
  Creates a raw js_library from a tarball. The resulting target will have the
  same runtime and compile deps.
  """
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
    cjsar = jsar,

    runtime_deps = runtime_deps(ctx.attr.deps),
    compile_deps = compile_deps(ctx.attr.deps),
  )

def _jsar_path(src, package):
  if package:
    return package +'/'+ src.basename

  path = src.short_path
  if path.startswith('../'):
    return path[3:]
  return path


def _build_src_jsar(ctx, srcs, package, output):
  arguments = [
    'bundle',
    '-output', output.path,
  ] + [
    '%s=/%s' % (s.path, _jsar_path(s, package)) for s in srcs
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


def build_jsar(ctx, files, package, jsars, output):
  """
  Builds and returns a fat jsar with this library and all its transitive
  dependencies
  """
  src_jsar = _build_src_jsar(
    ctx     = ctx,
    srcs    = files,
    package = package,
    output  = ctx.new_file(ctx.label.name +'.srcJsar'),
  )

  return _build_dep_jsar(ctx, jsars + [src_jsar], output)


def _js_library_impl(ctx):
  jsar  = ctx.outputs.jsar
  cjsar = ctx.outputs.cjsar

  # Package all library files into the jsar
  _build_src_jsar(
    ctx     = ctx,
    srcs    = ctx.files.srcs,
    package = ctx.attr.package,
    output  = jsar,
  )

  # Package all compile-time files into the cjsar
  compile_type = FileType(ctx.attr.compile_type)
  _build_src_jsar(
    ctx     = ctx,
    srcs    = compile_type.filter(ctx.files.srcs),
    package = ctx.attr.package,
    output  = cjsar,
  )

  ts_defs = depset()
  if ctx.attr.ts_defs:
    ts_defs = ctx.attr.ts_defs.ts_defs

  return struct(
    files   = depset([jsar, cjsar]),
    jsar    = jsar,
    cjsar   = cjsar,
    ts_defs = ts_defs,

    runtime_deps = runtime_deps(ctx.attr.deps),
    compile_deps = compile_deps(ctx.attr.deps),
  )


def node_driver(ctx, output, jsar, node, random_libdir, cmd, arguments=[]):
  safe_args = ["'%s'" % arg for arg in arguments]

  # See the documentation for `create_libdir` in the rule attribute declaration
  create_libdir = 'LIBDIR=$(mktemp -d --suffix=.node_driver)'
  if not random_libdir:
    create_libdir = 'LIBDIR=./node_modules && mkdir ./node_modules'

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

    # Creates a home to store all 3rd-party JS code needed for this binary
    # target to run. Unless `random_libdir` is set to `False`, this will be a
    # random directory in the tmp filesystem
    create_libdir,
    'trap "{ rm -rf $LIBDIR ; }" EXIT',

    '${RUNFILES}/%s unbundle -output $LIBDIR "${RUNFILES}/%s"' % (
      ctx.executable._jsar.short_path,
      jsar.short_path),

    'export NODE_PATH=$LIBDIR',
    '{node} $LIBDIR/{cmd} {arguments} "$@"'.format(
      node      = node.path,
      cmd       = cmd,
      arguments = ' '.join(safe_args),
    ),
  ]

  ctx.file_action(
    output     = output,
    content    = '\n'.join(content),
    executable = True,
  )


def _js_binary_impl(ctx):
  jsar = build_jsar(ctx,
    files   = ctx.files.src,
    package = None,
    jsars   = runtime_deps(ctx.attr.deps),
    output  = ctx.outputs.jsar,
  )

  node_driver(ctx,
    output        = ctx.outputs.executable,
    jsar          = jsar,
    node          = ctx.executable._node,
    random_libdir = ctx.attr.random_libdir,
    cmd           = _jsar_path(ctx.file.src, None),
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
    files    = depset([ctx.outputs.executable]),
    runfiles = runfiles,
    jsar     = jsar,
    main     = ctx.file.src,

    runtime_deps = depset(),
    compile_deps = depset(),
  )

# ------------------------------------------------------------------------------

jsar_attr = attr.label(
  default    = Label('@io_bazel_rules_js//js/tools:jsar-bin'),
  cfg        = 'host',
  executable = True)

node_attr = attr.label(
  default     = Label('//js/toolchain:node'),
  cfg         = 'host',
  executable  = True,
  allow_files = True)

js_lib_attr = attr.label_list(providers=js_lib_providers, cfg='target')
js_bin_attr = attr.label_list(providers=js_bin_providers, cfg='target')


jsar = rule(
  _jsar_impl,
  attrs = {
    'tar': attr.label(
      allow_files = FileType(['.tgz', '.tar.gz']),
      single_file = True,
      mandatory   = True),

    'deps':  js_lib_attr,
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
    'deps':    js_lib_attr,
    'ts_defs': attr.label(providers=['ts_defs']),

    'compile_type': attr.string_list(
      default = ['.d.ts'],
      doc = 'filetypes which will be included in the compile-time output',
    ),

    'package': attr.string(
      mandatory = False,
      doc = 'Allows this module to be imported from this location instead of ' +
            'the path where it resides in this workspace.'),

    '_jsar':   jsar_attr,
  },
  outputs = {
    'jsar':  '%{name}.jsar',
    'cjsar': '%{name}.cjsar',
  },
)

js_binary = rule(
  _js_binary_impl,
  executable = True,
  attrs = {
    'src':  attr.label(allow_files=True, single_file=True),
    'deps': js_bin_attr,

    'random_libdir': attr.bool(default=True,
      doc = 'By default, expand node dependencies into a random directory. ' +
            'However, in some cases, a predictable node_modules may be ' +
            'required. This this flag to False for those cases.'),

    '_jsar': jsar_attr,
    '_node': node_attr,
  },
  outputs = {
    'jsar': '%{name}.jsar',
  },
)
