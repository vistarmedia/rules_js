load(
    "@com_vistarmedia_rules_js//js/private:rules.bzl",
    "js_bin_providers",
    "js_lib_providers",
    "runtime_deps",
)

def esbuild_impl(ctx):
    jsars = runtime_deps([ctx.attr.src] + ctx.attr._node_shims)
    out = ctx.actions.declare_file("%s.js" % ctx.label.name)
    outputs = [out]

    esbuild_args = struct(
        entrypoint = str(ctx.attr.src.main.short_path),
        outfile = str(out.path),
        defines = ctx.attr.define,
        minify = bool(ctx.attr.minify),
        sourcemap = bool(ctx.attr.sourcemap),
    )

    arguments = ctx.actions.args()
    arguments.add_all(jsars, format_each = "--jsar=%s")
    arguments.add(esbuild_args.to_json())

    if ctx.attr.sourcemap:
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
        "_node_shims": attr.label_list(
            providers = js_lib_providers,
            default = [
                ":fs",
                "@assert//:lib",
                "@buffer//:lib",
                "@events//:lib",
                "@http//:lib",
                "@path//:lib",
                "@process//:lib",
                "@stream//:lib",
                "@url//:lib",
            ],
        ),
        "esbuild_bin": attr.label(
            cfg = "host",
            executable = True,
            default = Label("@com_vistarmedia_rules_js//js/tools:esbuild"),
        ),
    },
)
