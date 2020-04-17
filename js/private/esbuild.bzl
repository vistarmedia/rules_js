load(
    "@com_vistarmedia_rules_js//js/private:rules.bzl",
    "js_bin_providers",
    "runtime_deps",
)

def esbuild_impl(ctx):
    jsars = runtime_deps([ctx.attr.src])
    out = ctx.actions.declare_file("%s.js" % ctx.label.name)
    outputs = [out]

    arguments = ctx.actions.args()
    arguments.add_all(jsars, format_each = "--jsar=%s")
    arguments.add("--entrypoint=%s" % ctx.attr.src.main.short_path)
    arguments.add("--bundle")
    arguments.add("--outfile=%s" % out.path)
    for k, v in ctx.attr.define.items():
        arguments.add('--define:%s="%s"' % (k, v))

    if ctx.attr.minify:
        arguments.add("--minify")
    if ctx.attr.sourcemap:
        arguments.add("--sourcemap")
        out = ctx.actions.declare_file("%s.js.map" % ctx.label.name)
        outputs.append(out)

    ctx.actions.run(
        inputs = jsars,
        executable = ctx.executable.esbuild_bin,
        arguments = [arguments],
        outputs = outputs,
    )
    return DefaultInfo(files = depset(outputs))

esbuild = rule(
    esbuild_impl,
    attrs = {
        "src": attr.label(providers = js_bin_providers, mandatory = True),
        "minify": attr.bool(default = False),
        "define": attr.string_dict(),
        "sourcemap": attr.bool(default = False),
        "esbuild_bin": attr.label(
            cfg = "host",
            executable = True,
            default = Label("@com_vistarmedia_rules_js//js/tools:esbuild"),
        ),
    },
)
