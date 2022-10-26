load("@com_vistarmedia_rules_js//js:def.bzl", "js_binary")

config_setting(
    name = "k8",
    values = {"host_cpu": "k8"},
)

config_setting(
    name = "darwin",
    values = {"host_cpu": "darwin"},
)

filegroup(
    name = "node",
    srcs = select({
        ":k8": ["@nodejs_linux_amd64_vistar//:node"],
        ":darwin": ["@nodejs_darwin_amd64_vistar//:node"],
    }),
    visibility = ["//visibility:public"],
)
