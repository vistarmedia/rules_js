load('//js/private:browserify.bzl', _js_bundle = 'js_bundle')
load('//js/private:mocha.bzl', _js_test = 'js_test')
load('//js/private:node.bzl',
  _js_repositories = 'js_repositories',
  _chai_repositories = 'chai_repositories')

load('//js/private:npm.bzl',
  _npm_install = 'npm_install',
  _npm_tarball_install = 'npm_tarball_install')

load('//js/private:strict_js_deps.bzl',
  _strict_js_deps = 'strict_js_deps',
  _strict_js_src_deps = 'strict_js_src_deps')

load('//js/private:rules.bzl',
  _js_library = 'js_library',
  _js_binary = 'js_binary',
  _jsar = 'jsar')

js_bundle = _js_bundle
js_test = _js_test

js_repositories = _js_repositories
chai_repositories = _chai_repositories

npm_install = _npm_install
npm_tarball_install = _npm_tarball_install

js_library = _js_library
js_binary = _js_binary
jsar = _jsar
strict_js_deps = _strict_js_deps
strict_js_src_deps = _strict_js_src_deps
