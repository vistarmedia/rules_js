load("//js/private:npm.bzl", "npm_install", "npm_tarball_install")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _node_buildfile(arch):
    return "\n".join([
        'package(default_visibility=["//visibility:public"])',
        'filegroup(name="node", srcs=["node-v12.19.0-%s/bin/node"])' % arch,
    ])

def js_repositories():
    http_archive(
        name = "nodejs_linux_amd64",
        urls = ["http://nodejs.org/dist/v12.19.0/node-v12.19.0-linux-x64.tar.gz"],
        sha256 = "f37a5bf0965e8ab7b1b078392638778286ceee8fdb895c050889a61772944bda",
        build_file_content = _node_buildfile("linux-x64"),
    )

    http_archive(
        name = "nodejs_darwin_amd64",
        urls = ["http://nodejs.org/dist/v12.19.0/node-v12.19.0-darwin-x64.tar.gz"],
        sha256 = "751482c5060c2b705bd63739300a8d06bb33bcfacaf616eec78bbc20c55a627b",
        build_file_content = _node_buildfile("darwin-x64"),
    )

    # Grab Mocha + dependencies
    npm_install(
        name = "source-map-support",
        version = "0.5.12",
        sha256 = "e3c1870b1c31c84b60f370142e1f84ea04fb3473fad5531d8187faf367396cf4",
    )
    npm_install(
        name = "buffer-from",
        version = "1.0.0",
        sha256 = "3e21bab633cb80cfddf76d73cd774a436fdc4eceb47920049b1cc182efe122a1",
    )
    npm_install(
        name = "diff",
        version = "3.2.0",
        sha256 = "6d908956880eaf2cfa63bbe0c8aead7fca3ba3ddbd952afefc6a812bbcdb3259",
    )
    npm_install(
        name = "inherits",
        version = "2.0.3",
        sha256 = "7f5f58e9b54e87e264786e7e84d9e078aaf68c1003de9fa68945101e02356cdf",
    )
    npm_install(
        name = "mkdirp",
        version = "0.5.1",
        sha256 = "77b52870e8dedc68e1e7afcdadba34d3da6debe4f3aae36453ba151f1638bf24",
        ignore_deps = ["minimist"],
    )
    npm_tarball_install(
        name = "mocha",
        url = "https://s3.amazonaws.com/cookbooks.vistarmedia.com/third-party/mocha-full-7.1.0-types.tgz",
        sha256 = "c2a312ae4e89eaa116449aa7f3df5ddaab1270657f473bf1cf2d2abc6fbcb879",
        ignore_deps = [
            "glob",
            "debug",
            "find-up",
            "strip.json.comments",
            "growl",
            "ms",
            "wide-align",
            "escape-string-regexp",
            "yargs-parser",
            "yargs-unparser",
            "browser.stdout",
            "node-environment-flags",
            "which",
            "ansi-colors",
            "minimatch",
            "log-symbols",
            "he",
            "chokidar",
            "supports-color",
        ],
    )

def chai_repositories():
    # Grab Chai + dependencies
    npm_install(
        name = "assertion-error",
        version = "1.0.2",
        sha256 = "fcfb6f6be3104cb342819ca025bb310abab104fc90b882a1a2cddb4cd6139fb9",
    )
    npm_install(
        name = "check-error",
        version = "1.0.2",
        sha256 = "92554b32cbf947c79e2832277ee730015408dd75e753ee320ba1fc7bf5915dda",
    )
    npm_install(
        name = "deep-eql",
        version = "2.0.1",
        sha256 = "c4910d20b5818c1c48941dc3719800b511f44974c66e8145d968cfccf43870c5",
    )
    npm_install(
        name = "get-func-name",
        version = "2.0.0",
        sha256 = "791183ec55849b4e8fb87b356a6060d5a14dd72f1fe821750af8300e9afb4866",
    )
    npm_install(
        name = "pathval",
        version = "1.1.0",
        sha256 = "a950d68b409ee5daf91923ce180bab7dc1c93210ee29adbce1026be1ca04d541",
    )
    npm_install(
        name = "type-detect",
        version = "4.0.0",
        sha256 = "b600316f3f9dcb311a8be4f27e972fa5b5db5616cdfadf299225e0f56d5569a9",
    )
    npm_install(
        name = "chai",
        version = "4.0.2",
        sha256 = "36136ff5b9764f58b304b855f12cad26bb885ea763999d7d07862a23b275d557",
        type_version = "4.0.2",
        type_sha256 = "e966f65644fc50df3550287e20ae61de9255331bfcb2a23ae3878cc1e7763573",
    )
