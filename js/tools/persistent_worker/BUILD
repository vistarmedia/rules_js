load("@io_bazel_rules_js//js:def.bzl", "js_library")

js_library(
    name = "persistent_worker",
    srcs = [
        "index.js",
        "worker_protocol.json",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//js/tools:varint",
        "@protobufjs//:lib",
    ],
)
