load("@com_vistarmedia_rules_js//js/private:rules.bzl", "js_binary")

def _mocha_test_impl(ctx):
    cmd = [ctx.executable.driver.short_path] + \
          ["--require=source-map-support/register"] + \
          ["--require=%s" % r.short_path for r in ctx.files.requires]

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
        files = ctx.files.tests + ctx.files.data + ctx.files.requires,
    ).merge(ctx.attr.driver.default_runfiles)

    return [DefaultInfo(
        files = depset([ctx.outputs.executable]),
        runfiles = runfiles,
    )]

_mocha_test = rule(
    _mocha_test_impl,
    test = True,
    attrs = {
        "tests": attr.label_list(allow_files = True),
        "requires": attr.label_list(allow_files = True),
        "data": attr.label_list(),
        "reporter": attr.label(),
        "driver": attr.label(executable = True, cfg = "host"),
    },
)

def mocha_test(name, deps, srcs, reporter = None, **kwargs):
    all_deps = deps + [
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
        **kwargs
    )

js_test = mocha_test
