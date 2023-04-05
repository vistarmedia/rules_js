load("@com_vistarmedia_rules_js//js/private:rules.bzl", "js_binary")

def _mocha_test_impl(ctx):
    cmd = [ctx.executable.driver.short_path] + \
          ["--color"] + \
          ["--require=%s" % r.short_path for r in ctx.files.requires] + \
          ["--require=%s" % ctx.file.svg.path] + \
          ["--require=%s" % ctx.file.react_fix.path]

    if ctx.attr.source_map_support:
        cmd += ["--enable-source-maps"]

    if ctx.attr.has_dom:
        cmd += ["--require=%s" % ctx.file.jsdom.path]

    if ctx.attr.throw_warn:
        cmd += ["--require=%s" % ctx.file.console.path]

    if ctx.attr.reporter:
        cmd += ["--reporter=" + ctx.attr.reporter.label.package]

    if ctx.attr.debug:
        cmd.append("--inspect-brk")

    cmd += [test.short_path for test in ctx.files.tests]

    script = [
        "#!/bin/sh -e",
        "export NODE_ENV=test",
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
            ctx.files.console +
            ctx.files.svg +
            ctx.files.react_fix,
    ).merge(ctx.attr.driver.default_runfiles)

    return [DefaultInfo(
        files = depset([ctx.outputs.executable]),
        runfiles = runfiles,
    )]

_mocha_test = rule(
    _mocha_test_impl,
    test = True,
    attrs = {
        "console": attr.label(allow_single_file = True),
        "data": attr.label_list(),
        "debug": attr.bool(doc = "Enable Chrome debugger, see about:inspect"),
        "driver": attr.label(executable = True, cfg = "host"),
        "has_dom": attr.bool(doc = "Enable global DOM"),
        "jsdom": attr.label(allow_single_file = True),
        "react_fix": attr.label(allow_single_file = True),
        "reporter": attr.label(),
        "requires": attr.label_list(allow_files = True),
        "source_map_support": attr.bool(),
        "svg": attr.label(allow_single_file = True),
        "tests": attr.label_list(allow_files = True),
        "throw_warn": attr.bool(default = True),
    },
)

def mocha_test(name, deps, srcs, reporter = None, **kwargs):
    all_deps = deps + [
        "@global.jsdom//:lib",
        "@mocha//:lib",
    ]

    if "@jsdom//:lib" not in all_deps:
        all_deps += ["@jsdom//:lib"]

    if "@sinon//:lib" not in all_deps:
        all_deps += ["@sinon//:lib"]

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
        svg = "@com_vistarmedia_rules_js//js/private:svg.js",
        react_fix = "@com_vistarmedia_rules_js//js/private:reactFix.js",
        **kwargs
    )

js_test = mocha_test
