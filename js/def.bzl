load('//js/private:browserify.bzl', 'js_bundle')
load('//js/private:mocha.bzl', 'js_test')
load('//js/private:node.bzl',  'js_repositories')

load('//js/private:npm.bzl',
  'npm_install',
  'npm_tarball_install')

load('//js/private:rules.bzl',
  'js_library',
  'js_binary')

