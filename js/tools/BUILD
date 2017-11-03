load('@io_bazel_rules_go//go:def.bzl', 'go_binary')


go_binary(
  name = 'jsar-bin',
  srcs = ['jsar.go'],
  deps = ['@io_bazel_rules_js//js/tools/jsar:go_default_library'],
  visibility = ['//visibility:public'],
)

sh_test(
  name = 'test_simple_bundle',
  size = 'small',
  srcs = ['test_simple_bundle.sh'],
  data = [':jsar-bin'],
)

sh_test(
  name = 'test_simple_unbundle',
  size = 'small',
  srcs = ['test_simple_unbundle.sh'],
  data = [':jsar-bin'],
)

test_suite(
  name = 'test',
  tests = [
    ':test_simple_bundle',
    ':test_simple_unbundle',
  ],
)
