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
parser.add_argument('--rename')
parser.add_argument('--npm_tar', nargs='+')
parser.add_argument('--ignore_deps', nargs='*')
parser.add_argument('--ignore_paths', nargs='*', default=[])


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

def _contains_ignored_path(path, ignore_paths):
  for ignored_path in ignore_paths:
    if path.startswith(ignored_path):
      return True
  return False


def _package_roots(src, ignore_paths):
  """
  Extract the package roots from an npm tarball. A spec for exactly how this
  works would be clearly too much to ask, so we're saying any directory that
  contains a package.json is a root.

  Any paths contained in 'ignore_paths' will be skipped. Useful if there is a
  file called package.json that isnt meant to be a npm package.

  Return the root, and the deserialized package.json
  """
  for member in src.getmembers():
    if not member.isfile(): continue
    name = member.name

    # Do not look in nested node_modules directories for dependencies
    if '/node_modules/' in name:
      continue

    if _contains_ignored_path(name, ignore_paths):
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


def _copy_tar_files(src, dst, ignore_paths, rename):
  deps = {}
  for root, package in _package_roots(src, ignore_paths):
    package['name'] = rename.get(package['name'], package['name'])
    deps.update(_copy_package(src, dst, root, package))
  return deps


def _external_name(name):
  """
  Bazel does not allow dashes in external names. Follow the convention of
  replacing dashes with dots. Consumers of NPM dependencies need to be aware of
  this rule.
  Make sure to keep this in sync with _external_name in
    //tools/build_rules/rules_js/js/private:npm.bzl
  """
  return name.replace('-', '.')\
             .replace('/', '.')\
             .replace('@', '')

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

    bazel_name = _external_name(dep)

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


def _main(
  buildfile, js_tar_name, npm_tar_names, ignore_deps, ignore_paths, rename):

  js_tar = tarfile.open(js_tar_name, 'w:gz')
  deps   = {}

  for npm_tar_name in npm_tar_names:
    with tarfile.open(npm_tar_name) as npm_tar:
      deps.update(_copy_tar_files(npm_tar, js_tar, ignore_paths, rename))

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

  rename = {}
  if params.rename:
    parts = params.rename.split(':')
    rename = {parts[0]: parts[1]}

  _main(
    buildfile      = params.buildfile,
    js_tar_name    = params.output,
    npm_tar_names  = params.npm_tar,
    ignore_deps    = params.ignore_deps,
    ignore_paths   = params.ignore_paths,
    rename         = rename,
  )

  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
