load("//js/private:npm.bzl", "npm_install", "npm_tarball_install")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _node_buildfile(arch):
    return "\n".join([
        'package(default_visibility=["//visibility:public"])',
        'filegroup(name="node", srcs=["node-v8.11.4-%s/bin/node"])' % arch,
    ])

def js_repositories():
    http_archive(
        name = "nodejs_linux_amd64",
        urls = ["http://nodejs.org/dist/v8.11.4/node-v8.11.4-linux-x64.tar.gz"],
        sha256 = "c69abe770f002a7415bd00f7ea13b086650c1dd925ef0c3bf8de90eabecc8790",
        build_file_content = _node_buildfile("linux-x64"),
    )

    http_archive(
        name = "nodejs_darwin_amd64",
        urls = ["http://nodejs.org/dist/v8.11.4/node-v8.11.4-darwin-x64.tar.gz"],
        sha256 = "aa1de83b388581d0d9ec3276f4526ee67e17e0f1bc0deb5133f960ce5dc9f1ef",
        build_file_content = _node_buildfile("darwin-x64"),
    )

    # Meriyah parses JS to find dependencies
    npm_install(
        name = "meriyah",
        version = "1.6.10",
        sha256 = "f44b1eebc09c3d8e4c56f43e4993fd2e61d505c190a126209bb077687f3a824c",
    )

    # Grab Mocha + dependencies
    npm_install(
        name = "graceful-readlink",
        version = "1.0.1",
        sha256 = "c1ce83682d563874517386a13c364eb0a8494e99a69203cff264a1381cb3a300",
    )
    npm_install(
        name = "commander",
        version = "2.9.0",
        sha256 = "197a1e0b408bc686fbf62ed5ef43210251c616ba1b09721e8299d4484217bd47",
    )
    npm_install(
        name = "ms",
        version = "0.7.2",
        sha256 = "4fdc14e963913ad66571ec3753d2169abbb41ca25f1d92b26efe46afee85e435",
    )
    npm_install(
        name = "debug",
        version = "2.6.0",
        sha256 = "a8178fc9b10b81311bc26d74e9d17ecfb14fbbbf7778d600ae246861d4f501eb",
    )
    npm_install(
        name = "diff",
        version = "3.2.0",
        sha256 = "6d908956880eaf2cfa63bbe0c8aead7fca3ba3ddbd952afefc6a812bbcdb3259",
    )
    npm_install(
        name = "has-flag",
        version = "2.0.0",
        sha256 = "0915ab7bab71d000cd1ccb70b4e29afe1819183538339c8953bc9d3344bc4241",
    )
    npm_install(
        name = "supports-color",
        version = "3.1.2",
        sha256 = "38d3e0f27fefc6ace202c5afcdc49bb06fd10ea9e078fcc36ee7af603e9c9665",
    )
    npm_install(
        name = "escape-string-regexp",
        version = "1.0.5",
        sha256 = "e50c792e76763d0c74506297add779755967ca9bbd288e2677966a6b7394c347",
    )
    npm_install(
        name = "path-is-absolute",
        version = "1.0.1",
        sha256 = "6e6d709f1a56942514e4e2c2709b30c7b1ffa46fbed70e714904a3d63b01f75c",
    )
    npm_install(
        name = "balanced-match",
        version = "0.4.2",
        sha256 = "2af5559389b5274d3a8b5834dad7bbe0ca51509324f8cc2ecc2a368de4e20ad8",
    )
    npm_install(
        name = "concat-map",
        version = "0.0.1",
        sha256 = "35902dd620cf0058c49ea614120f18a889d984269a90381b7622e79c2cfe4261",
    )
    npm_install(
        name = "brace-expansion",
        version = "1.1.6",
        sha256 = "7f3496919ed6a064939c3c07c3fefd45c7163e81792c3146f91e156708620a0c",
    )
    npm_install(
        name = "minimatch",
        version = "3.0.3",
        sha256 = "bcd13daf575da13da23d57b170d33b3d7d80e7ea319d8cba2bea5b842b2a5d81",
    )
    npm_install(
        name = "inflight",
        version = "1.0.6",
        sha256 = "5a9fdcf59874af6ad3b413b6815d5afaaea34939a3bee20e1e50f7830031889b",
    )
    npm_install(
        name = "wrappy",
        version = "1.0.2",
        sha256 = "aff3730d91b7b1e143822956d14608f563163cf11b9d0ae602df1fe1e430fdfb",
    )
    npm_install(
        name = "once",
        version = "1.4.0",
        sha256 = "cf51460ba370c698f68b976e514d113497339ba018b6003e8e8eb569c6fccfcf",
    )
    npm_install(
        name = "inherits",
        version = "2.0.3",
        sha256 = "7f5f58e9b54e87e264786e7e84d9e078aaf68c1003de9fa68945101e02356cdf",
    )
    npm_install(
        name = "fs.realpath",
        version = "1.0.0",
        sha256 = "9e80cb8713125aa53df81a29626f7b81f26a9be1cd41840b3ccdcae4d52e8f9c",
    )
    npm_install(
        name = "glob",
        version = "7.1.1",
        sha256 = "17232040681c8bfa5badd0801a977fa79c05f0388974e8921fffabd380d10c0b",
    )
    npm_install(
        name = "json3",
        version = "3.3.2",
        sha256 = "703e754f648282fa455bd84a347d4105c9bb521c80983d54ec9f35f994558b5e",
    )
    npm_install(
        name = "mkdirp",
        version = "0.5.1",
        sha256 = "77b52870e8dedc68e1e7afcdadba34d3da6debe4f3aae36453ba151f1638bf24",
        ignore_deps = ["minimist"],
    )
    npm_install(
        name = "lodash.create",
        version = "4.2.0",
        sha256 = "aeeb60f75c0906fda54ca19b17fb1af591eecd92c053e3dc4e54e360312f3fc6",
    )
    npm_install(
        name = "mocha",
        version = "3.2.0",
        sha256 = "909a629739cbe09e73465b0615d0a7cc634041d8395787c8e8976e1a925c01c2",
        type_version = "2.2.37",
        type_sha256 = "5d58404cf416052ba01b3c419a431d3cc253b23414bbdabc83e9961f82ac6e0f",
        ignore_deps = [
            "browser.stdout",
            "growl",
        ],
    )

    npm_install(
        name = "source-map-support",
        version = "0.4.18",
        sha256 = "82e7eb70bc5039b1e194e98f65eea2740bba35a4eda384eadba7d5867a60ade0",
    )
    npm_install(
        name = "source-map",
        version = "0.5.6",
        sha256 = "5b6d427a47255f75c923ceaa50b39567837a784f988fb5937b55bcfa6521e971",
    )

    npm_tarball_install(
        name = "browserify",
        url = "https://s3.amazonaws.com/js.vistarmedia.com/browserify-16.0.0.tgz",
        sha256 = "eef85603a1befaa7c4315f537b7d4deb02275ff7a69c1929756d6d7784c13b0e",
        ignore_deps = [
            "JSONStream",
            "assert",
            "qq",
            "browser-pack",
            "browser-resolve",
            "browserify-zlib",
            "buffer",
            "cached-path-relative",
            "concat-stream",
            "console-browserify",
            "constants-browserify",
            "crypto-browserify",
            "defined",
            "deps-sort",
            "domain-browser",
            "duplexer2",
            "events",
            "glob",
            "has",
            "htmlescape",
            "https-browserify",
            "inherits",
            "insert-module-globals",
            "labeled-stream-splicer",
            "module-deps",
            "os-browserify",
            "parents",
            "path-browserify",
            "process",
            "punycode",
            "querystring-es3",
            "read-only-stream",
            "readable-stream",
            "resolve",
            "shasum",
            "shell-quote",
            "stream-browserify",
            "stream-http",
            "string_decoder",
            "subarg",
            "syntax-error",
            "through2",
            "timers-browserify",
            "tty-browserify",
            "url",
            "util",
            "vm-browserify",
            "xtend",
        ],
    )

    npm_install(
        name = "js-tokens",
        version = "3.0.2",
        sha256 = "85ce7a76734264e093bcb1dbbe6d4d4130ee0a7fa562e7608693ee8c3c197d19",
    )
    npm_install(
        name = "loose-envify",
        version = "1.3.1",
        sha256 = "fb526ac195ab33e34c3a5fc5a4f68ae865de3310209191c2f5ab56d9631ce088",
    )

    npm_tarball_install(
        name = "uglifyjs",
        url = "https://s3.amazonaws.com/js.vistarmedia.com/uglify-js-3.0.24.tgz",
        sha256 = "afc191cfb99b252d750fdae86bcd0e1e74a764a470d0298ffb6655322ae9a50f",
        ignore_deps = [
            "commander",
            "source-map",
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
