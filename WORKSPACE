load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

workspace(name = "com_vistarmedia_rules_js")

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "099a9fb96a376ccbbb7d291ed4ecbdfd42f6bc822ab77ae6f1b5cb9e914e94fa",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.35.0/rules_go-v0.35.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.35.0/rules_go-v0.35.0.zip",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "de69a09dc70417580aabf20a28619bb3ef60d038470c7cf8442fafcf627c21cb",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.24.0/bazel-gazelle-v0.24.0.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.24.0/bazel-gazelle-v0.24.0.tar.gz",
    ],
)

load(
    "@io_bazel_rules_go//go:def.bzl",
    "go_register_toolchains",
    "go_rules_dependencies",
)
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(
    nogo = "@//:nogo_cfg",
    version = "1.19.2",
)

gazelle_dependencies()

load("@bazel_gazelle//:deps.bzl", "go_repository")

go_repository(
    name = "com_github_pkg_errors",
    importpath = "github.com/pkg/errors",
    tag = "v0.8.0",
)

load("//js:def.bzl", "chai_repositories", "js_repositories")

js_repositories()

chai_repositories()
