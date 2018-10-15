load("@io_bazel_rules_go//go:def.bzl", "go_binary")
load("@io_bazel_rules_js//js:def.bzl", "js_binary", "js_library")

go_binary(
    name = "jsar-bin",
    srcs = ["jsar.go"],
    visibility = ["//visibility:public"],
    deps = ["@io_bazel_rules_js//js/tools/jsar:go_default_library"],
)

js_binary(
    name = "mocha",
    testonly = True,
    src = "mocha.js",
    visibility = ["//visibility:public"],
    deps = ["@mocha//:lib"],
)

exports_files(
    ["mocha.js"],
    visibility = ["//visibility:public"],
)

js_library(
    name = "varint",
    srcs = ["varint.js"],
    visibility = [":__subpackages__"],
)

sh_test(
    name = "test_simple_bundle",
    size = "small",
    srcs = ["test_simple_bundle.sh"],
    data = [":jsar-bin"],
)

sh_test(
    name = "test_simple_unbundle",
    size = "small",
    srcs = ["test_simple_unbundle.sh"],
    data = [":jsar-bin"],
)
