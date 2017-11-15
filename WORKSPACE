workspace(name='io_bazel_rules_js')

# We are using this commit instead of 0.6 release because of this issue:
# https://github.com/bazelbuild/rules_go/issues/896
git_repository(
  name = 'io_bazel_rules_go',
  remote = 'https://github.com/bazelbuild/rules_go.git',
  commit = '561efc61f3daa04ad16ff6f75908a88d48c01bb5'
)
load('@io_bazel_rules_go//go:def.bzl', 'go_repositories')
go_repositories()
