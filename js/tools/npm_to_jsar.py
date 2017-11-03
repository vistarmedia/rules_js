#!/usr/bin/env python
import argparse
import json
import os
import string
import sys
import tarfile

parser = argparse.ArgumentParser('Convert NPM tarballs into js_tar impls')
parser.add_argument('--buildfile')
parser.add_argument('--output')
parser.add_argument('--npm_tar', nargs='+')
parser.add_argument('--ignore_deps', nargs='*')


_BUILDFILE = string.Template("""
load('@io_bazel_rules_js//js/private:rules.bzl', 'jsar')
${dep_infos}
jsar(
  name = 'lib',
  tar  = '${js_tar}',
  deps = ${deps},
  visibility = ${visibility},
)
""")


def _package_roots(src):
  """
  Extract the package roots from an npm tarball. A spec for exactly how this
  works would be clearly too much to ask, so we're saying any directory that
  contains a package.json is a root.

  Return the root, and the deserialized package.json
  """
  for member in src.getmembers():
    if not member.isfile(): continue
    name = member.name

    # Do not look in nested node_modules directories for dependencies
    if '/node_modules/' in name:
      continue

    if os.path.basename(name) == 'package.json':
      root    = os.path.dirname(name)
      package = json.load(src.extractfile(member))
      yield root, package


def _copy_package(src, dst, root, package):
  dst_dir = package['name']
  deps    = {}

  for dep, version in package.get('dependencies', {}).items():
    # Ignore dependencies in the @types/ namepace
    if dep.startswith('@types/'): continue

    deps[dep] = version

  for member in src.getmembers():
    if not member.isfile(): continue
    if not member.path.startswith(root): continue

    package_path = member.path.replace(root+'/', '', 1)
    dst_path = os.path.join(dst_dir, package_path)

    info = tarfile.TarInfo(dst_path)
    info.size = member.size
    dst.addfile(info, fileobj=src.extractfile(member.path))

  return deps


def _copy_tar_files(src, dst):
  deps = {}
  for root, package in _package_roots(src):
    deps.update(_copy_package(src, dst, root, package))
  return deps


def _write_buildfile(filename, deps, js_tar_name, ignore_deps,
                     visibility=None):
  if visibility is None:
    visibility = ['//visibility:public']

  to_ignore = set()
  if ignore_deps: to_ignore = set(ignore_deps)

  bazel_deps = []
  dep_infos  = []
  for dep in sorted(deps.keys()):
    if dep in to_ignore: continue

    bazel_name = dep.replace('-', '.')
    if bazel_name in to_ignore: continue

    version = deps[dep]

    bazel_deps.append('@%s//:lib' % bazel_name)
    dep_infos.append('# %s %s' % (dep, version))

  with open(filename, 'w') as out:
    out.write(_BUILDFILE.substitute({
      'js_tar':     os.path.basename(js_tar_name),
      'deps':       json.dumps(bazel_deps, indent=4),
      'dep_infos':  '\n'.join(dep_infos),
      'visibility': json.dumps(visibility),
    }))


def _main(buildfile, js_tar_name, npm_tar_names, ignore_deps):
  js_tar = tarfile.open(js_tar_name, 'w:gz')
  deps   = {}

  for npm_tar_name in npm_tar_names:
    with tarfile.open(npm_tar_name) as npm_tar:
      deps.update(_copy_tar_files(npm_tar, js_tar))

  _write_buildfile(buildfile, deps, js_tar_name, ignore_deps)


def _parse_args(args):
  params = parser.parse_args(args)

  if params.buildfile is None or \
     params.output is None or \
     params.npm_tar is None:
    return None

  return params


def main(args):
  params = _parse_args(args[1:])
  if params is None:
    parser.print_help()
    return 2

  _main(
    buildfile      = params.buildfile,
    js_tar_name    = params.output,
    npm_tar_names  = params.npm_tar,
    ignore_deps    = params.ignore_deps,
  )

  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
