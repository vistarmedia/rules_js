load("@io_bazel_rules_js//js:def.bzl", "js_binary")

js_binary(
    name = "check_strict_deps",
    src = "check_strict_deps.js",
    visibility = ["//visibility:public"],
    deps = [
        "@io_bazel_rules_js//js/tools/jsar",
    ],
)
