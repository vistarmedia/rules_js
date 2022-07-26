load("@com_vistarmedia_rules_js//js/private:rules.bzl", "js_empty_package")

# Some packages try to import 'fs' but dont use it on the browser. Just adding
# a dummy package so the require stmt doesnt fail.
js_empty_package(
    name = "fs",
    visibility = ["//visibility:public"],
)

exports_files(["jsdom.js"])
