load("@com_vistarmedia_rules_js//js:def.bzl", "js_binary")

config_setting(
    name = "k8",
    values = {"host_cpu": "k8"},
)

config_setting(
    name = "darwin",
    values = {"host_cpu": "darwin"},
)

config_setting(
    name = "darwin_arm64",
    values = {"host_cpu": "darwin_arm64"},
)

filegroup(
    name = "node",
    srcs = select({
        ":k8": ["@nodejs_linux_amd64_vistar//:node"],
        ":darwin": ["@nodejs_darwin_amd64_vistar//:node"],
        ":darwin_arm64": ["@nodejs_darwin_arm64_vistar//:node"],
    }),
    visibility = ["//visibility:public"],
)
