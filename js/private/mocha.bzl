load("@com_vistarmedia_rules_js//js/private:rules.bzl", "js_binary")

def _mocha_test_impl(ctx):
    cmd = [ctx.executable.driver.short_path] + \
          ["--color"] + \
          ["--require=source-map-support/register"] + \
          ["--require=%s" % r.short_path for r in ctx.files.requires]

    if ctx.attr.has_dom:
        cmd += ["--require=%s" % ctx.file.jsdom.path]

    if ctx.attr.throw_warn:
        cmd += ["--require=%s" % ctx.file.console.path]

    if ctx.attr.reporter:
        cmd += ["--reporter=" + ctx.attr.reporter.label.package]

    cmd += [test.short_path for test in ctx.files.tests]

    script = [
        "#!/bin/sh -e",
        " ".join(cmd),
    ]

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join(script),
    )

    runfiles = ctx.runfiles(
        files =
            ctx.files.tests +
            ctx.files.data +
            ctx.files.requires +
            ctx.files.jsdom +
            ctx.files.console,
    ).merge(ctx.attr.driver.default_runfiles)

    return [DefaultInfo(
        files = depset([ctx.outputs.executable]),
        runfiles = runfiles,
    )]

_mocha_test = rule(
    _mocha_test_impl,
    test = True,
    attrs = {
        "has_dom": attr.bool(doc = "Enable global DOM"),
        "jsdom": attr.label(allow_single_file = True),
        "tests": attr.label_list(allow_files = True),
        "requires": attr.label_list(allow_files = True),
        "data": attr.label_list(),
        "reporter": attr.label(),
        "driver": attr.label(executable = True, cfg = "host"),
        "throw_warn": attr.bool(default = True),
        "console": attr.label(allow_single_file = True),
    },
)

def mocha_test(name, deps, srcs, reporter = None, **kwargs):
    all_deps = deps + [
        "@global.jsdom//:lib",
        "@jsdom//:lib",
        "@mocha//:lib",
        "@source.map.support//:lib",
    ]
    if reporter:
        all_deps += [reporter]

    js_binary(
        name = name + ".driver",
        testonly = True,
        src = "@com_vistarmedia_rules_js//js/tools:mocha.js",
        deps = all_deps,
    )

    _mocha_test(
        name = name,
        driver = name + ".driver",
        tests = srcs,
        reporter = reporter,
        jsdom = "@com_vistarmedia_rules_js//js/private:jsdom.js",
        console = "@com_vistarmedia_rules_js//js/private:consoleThrow.js",
        **kwargs
    )

js_test = mocha_test
