def _external_name(name):
  """
  Bazel does not allow dashes in external names. Follow the convention of
  replacing dashes with dots. Consumers of NPM dependencies need to be aware of
  this rule
  """
  return name.replace('-', '.')\
             .replace('/', '.')\
             .replace('@', '')


def _download_tarball(ctx, name, url, sha256=None):
  # `ctx.download` is a direct Java method. Keyword arguments are not allowed
  # for this call.
  if sha256:
    ctx.download(url, name, sha256)
  else:
    ctx.download(url, name)

  return ctx.path(name)


def _npm_registry_url(package, version, namespace=None):
  url_safe_package = package.replace('/', '%2F')
  url_fragments = ['http://registry.npmjs.org']

  if namespace:
    url_fragments.append(namespace)

  url_fragments += [
    url_safe_package,
    '-',
    '%s-%s.tgz' % (url_safe_package, version),
  ]

  return '/'.join(url_fragments)


def _create_workspace(ctx, tarballs):
  """
  Creates a new workspace populated by a set of given tarballs
  """
  ignore_deps = list(ctx.attr.ignore_deps)
  ignore_deps.append(ctx.attr.package)

  ctx.file('WORKSPACE', "workspace(name='%s')\n" % ctx.name, False)

  npm_tars = []
  for tarball in tarballs:
    npm_tar = _download_tarball(
      ctx,
      name   = tarball.name,
      url    = tarball.url,
      sha256 = tarball.sha256,
    )
    npm_tars.append(npm_tar)

  cmd = [
    ctx.path(ctx.attr._npm_to_jsar),
    '--buildfile', ctx.path('BUILD'),
    '--output',    ctx.path('lib.tgz'),
  ]

  cmd += ['--npm_tar'] + npm_tars
  if ignore_deps:
    cmd += ['--ignore_deps'] + ignore_deps

  if ctx.attr.ignore_paths:
    cmd += ['--ignore_paths'] + ctx.attr.ignore_paths

  if ctx.attr.rename:
    cmd += ['--rename', ctx.attr.package + ':' + ctx.attr.name]

  ctx.execute(cmd, quiet=False)


def _npm_install_impl(ctx):
  """
  Installs a package from the npm registry with an optional type declaration in
  the @type namespace.
  """
  if not ctx.attr.version and not ctx.attr.type_version:
    fail('npm_install rule must declare either a version or type_version')

  tarballs = []

  if ctx.attr.version:
    url = _npm_registry_url(
      package = ctx.attr.package,
      version = ctx.attr.version,
    )

    tarballs.append(struct(
      url     = url,
      sha256  = ctx.attr.sha256,
      name    = 'package.tgz',
    ))

  if ctx.attr.type_version:
    url = _npm_registry_url(
      package   = ctx.attr.package,
      version   = ctx.attr.type_version,
      namespace = '@types',
    )

    tarballs.append(struct(
      url     = url,
      sha256  = ctx.attr.type_sha256,
      name    = 'type.tgz',
    ))

  _create_workspace(ctx, tarballs)


def _npm_tarball_install_impl(ctx):
  """
  Installs a npm tarball from a fully-qualified URL with an optional type
  declaration, fetched from the npm registry.
  """
  tarballs = [
    struct(
      url    = ctx.attr.url,
      sha256 = ctx.attr.sha256,
      name   = 'package.tgz',
    )
  ]

  if ctx.attr.type_version:
    url = _npm_registry_url(
      package   = ctx.attr.package,
      version   = ctx.attr.type_version,
      namespace = '@types',
    )

    tarballs.append(struct(
      url     = url,
      sha256  = ctx.attr.type_sha256,
      name    = 'type.tgz',
    ))

  _create_workspace(ctx, tarballs)


attrs = {
  'package':       attr.string(),
  'sha256':        attr.string(),
  'type_version':  attr.string(),
  'type_sha256':   attr.string(),
  'ignore_deps':   attr.string_list(),
  'ignore_paths':  attr.string_list(),
  'rename':        attr.bool(default=False),

  '_npm_to_jsar': attr.label(
    default    = Label('//js/tools:npm_to_jsar.py'),
    cfg        = 'host',
    executable = True),
}

_npm_install = repository_rule(
  _npm_install_impl,
  attrs = attrs + {'version': attr.string()},
)


_npm_tarball_install = repository_rule(
  _npm_tarball_install_impl,
  attrs = attrs + {'url': attr.string(mandatory=True)},
)

def npm_install(name, **kwargs):
  """
  Sanitizes the given name and creates a sanitized external target using the
  `_npm_install` rule.
  """
  external = _external_name(name)
  rename = False
  from_pkg = kwargs.pop('from_package', None)
  pkg_name = name
  if from_pkg:
    pkg_name = from_pkg
    rename = True
  return _npm_install(name=external, package=pkg_name, rename=rename, **kwargs)

def npm_tarball_install(name, **kwargs):
  external = _external_name(name)
  return _npm_tarball_install(name=external, package=name, **kwargs)
