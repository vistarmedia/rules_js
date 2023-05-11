load("//js/private:npm.bzl", "npm_install", "npm_tarball_install")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _node_buildfile(arch):
    return "\n".join([
        'package(default_visibility=["//visibility:public"])',
        'filegroup(name="node", srcs=["node-v18.15.0-%s/bin/node"])' % arch,
    ])

def js_repositories():
    http_archive(
        name = "nodejs_linux_amd64_vistar",
        urls = ["https://nodejs.org/dist/v18.15.0/node-v18.15.0-linux-x64.tar.xz"],
        sha256 = "c8c5fa53ce0c0f248e45983e86368e0b1daf84b77e88b310f769c3cfc12682ef",
        build_file_content = _node_buildfile("linux-x64"),
    )

    http_archive(
        name = "nodejs_darwin_amd64_vistar",
        urls = ["https://nodejs.org/dist/v18.15.0/node-v18.15.0-darwin-x64.tar.gz"],
        sha256 = "76add174d2d3f98da08907412e82add7352b8cb6f639324d352a65c084b99c7e",
        build_file_content = _node_buildfile("darwin-x64"),
    )

    # Grab Mocha + dependencies
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
        url = "https://s3.amazonaws.com/cookbooks.vistarmedia.com/third-party/mocha-10.0.0.tgz",
        sha256 = "681afbde18e90ee06705273fa8f9b9b7994097dbce62132490eb3029f838baaf",
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
            "serialize-javascript",
            "nanoid",
            "ungap.promise.all.settled",
            "workerpool",
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
