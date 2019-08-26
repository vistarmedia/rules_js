load("@com_vistarmedia_rules_js//js:def.bzl", "js_binary", "js_library", "js_test", "strict_js_deps")

js_binary(
    name = "check_strict_requires",
    src = "check_strict_requires.js",
    visibility = ["//visibility:public"],
    deps = [
        ":lib",
        "@com_vistarmedia_rules_js//js/tools/jsar",
        "@meriyah//:lib",
    ],
)

js_library(
    name = "lib",
    srcs = [
        "logger.js",
        "scope.js",
        "visitor.js",
    ],
)

strict_js_deps(
    name = "lib.ok",
    src = ":lib",
)

js_test(
    name = "test",
    size = "small",
    srcs = ["visitor_spec.js"],
    deps = [
        ":lib",
        "@chai//:lib",
        "@meriyah//:lib",
        "@sinon//:lib",
    ],
)
