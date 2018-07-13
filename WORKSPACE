workspace(name='io_bazel_rules_js')

# We are using this commit instead of 0.6 release because of this issue:
# https://github.com/bazelbuild/rules_go/issues/896
http_archive(
  name = 'io_bazel_rules_go',
  url = 'https://github.com/bazelbuild/rules_go/archive/561efc61f3daa04ad16ff6f75908a88d48c01bb5.tar.gz',
  strip_prefix = 'rules_go-561efc61f3daa04ad16ff6f75908a88d48c01bb5',
  sha256 = 'd9b942ba688434c67188dbcbde02156c76266d353103b974acee2ab00d8553fe',
)
load('@io_bazel_rules_go//go:def.bzl', 'go_repositories')
go_repositories()
