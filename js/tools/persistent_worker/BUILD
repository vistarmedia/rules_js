load("@com_vistarmedia_rules_js//js:def.bzl", "js_library")

js_library(
    name = "persistent_worker",
    srcs = [
        "index.js",
        "work.js",
        "worker_protocol.json",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//js/tools:varint",
        "@google.protobuf//:lib",
    ],
)
