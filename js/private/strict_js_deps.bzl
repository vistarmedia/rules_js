load("@com_vistarmedia_rules_js//js/private:rules.bzl", "js_lib_providers")

def _strict_deps_target(ctx, srcs, src_jsar, dep_jsars):
    inputs = dep_jsars + srcs
    ignored_jsars = [jsar.cjsar for jsar in ctx.attr.ignored_strict_deps]
    src_jsar_path = None

    if src_jsar:
        inputs = inputs + [src_jsar]
        src_jsar_path = src_jsar.path

    paths = struct(
        src_jsar = src_jsar_path,
        srcs = [src.path for src in srcs],
        output = ctx.outputs.ok.path,
        deps = [dep.path for dep in dep_jsars],
        ignored_deps = [jsar.path for jsar in ignored_jsars],
    )

    ctx.actions.run(
        inputs = inputs,
        tools = [ctx.executable._node],
        outputs = [ctx.outputs.ok],
        arguments = [paths.to_json()],
        executable = ctx.executable._check_strict_deps,
        mnemonic = "StrictJsDeps",
    )

def _strict_js_deps(ctx):
    deps = ctx.attr.src.direct_cdeps
    _strict_deps_target(ctx, [], ctx.attr.src.jsar, deps)

def _strict_js_src_deps(ctx):
    deps = [jsar.cjsar for jsar in ctx.attr.deps]
    _strict_deps_target(ctx, ctx.files.srcs, None, deps)

strict_js_deps = rule(
    _strict_js_deps,
    attrs = {
        "src": attr.label(providers = js_lib_providers),
        "ignored_strict_deps": attr.label_list(providers = js_lib_providers),
        "_check_strict_deps": attr.label(
            default = Label("@com_vistarmedia_rules_js//js/tools/check_strict_deps:check_strict_deps"),
            executable = True,
            cfg = "host",
        ),
        "_node": attr.label(
            default = Label("@com_vistarmedia_rules_js//js/toolchain:node"),
            cfg = "host",
            executable = True,
            allow_single_file = True,
        ),
    },
    doc = """
Generate a target from a library[1] that will only be created if the sources
require exactly their "deps." So:
  * You can't require something that isn't a dep
  * You can't have a dep that isn't required

[1] Contrast to sources below
""",
    outputs = {
        "ok": "%{name}.ok",
    },
)

strict_js_src_deps = rule(
    _strict_js_src_deps,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = js_lib_providers),
        "ignored_strict_deps": attr.label_list(providers = js_lib_providers),
        "_check_strict_deps": attr.label(
            default = Label("@com_vistarmedia_rules_js//js/tools/check_strict_deps:check_strict_deps"),
            executable = True,
            cfg = "host",
        ),
        "_node": attr.label(
            default = Label("@com_vistarmedia_rules_js//js/toolchain:node"),
            cfg = "host",
            executable = True,
            allow_single_file = True,
        ),
    },
    doc = """
Generate a target from source files and a dep list[1] that will only be created
if the sources require exactly the deps" So:
  * You can't require something that isn't a dep
  * You can't have a dep that isn't required

[1] Contrast to libraries above
""",
    outputs = {
        "ok": "%{name}.ok",
    },
)
