load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("@io_bazel_rules_js//js:def.bzl", "js_library", "js_test")

go_library(
    name = "go_default_library",
    srcs = ["jsar.go"],
    importpath = "vistarmedia.com/rules_js/js/tools/jsar",
    visibility = ["//visibility:public"],
)

js_library(
    name = "jsar",
    srcs = ["jsar.js"],
    visibility = ["//visibility:public"],
)

js_test(
    name = "test",
    size = "small",
    srcs = ["jsarSpec.js"],
    deps = [
        ":jsar",
        "@chai//:lib",
    ],
)
