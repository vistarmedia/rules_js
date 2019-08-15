load('//js/private:browserify.bzl', 'js_bundle')
load('//js/private:mocha.bzl', 'js_test')
load('//js/private:node.bzl',  'js_repositories', 'chai_repositories')

load('//js/private:npm.bzl',
  'npm_install',
  'npm_tarball_install')

load('//js/private:rules.bzl',
  'js_library',
  'js_binary',
  'jsar')

load('//js/private:strict_js_deps.bzl', 'strict_js_deps', 'strict_js_src_deps')
