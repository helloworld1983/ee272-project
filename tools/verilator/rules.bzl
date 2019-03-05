"""Rules for compiling Verilog files to C++ using Verilator"""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "CPP_LINK_STATIC_LIBRARY_ACTION_NAME")
load("@//tools:verilog.bzl", "get_transitive_sources")

def _link_static_library(
        ctx,
        feature_configuration,
        cc_compilation_outputs,
        cc_toolchain,
        linkopts = [],
        linking_contexts = []):
    """Link object files into a static library"""
    static_library = ctx.actions.declare_file("lib{name}.a".format(name = ctx.label.name))
    link_tool = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
    )
    link_variables = cc_common.create_link_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        output_file = static_library.path,
        is_using_linker = False,  # False for static library
        is_linking_dynamic_library = False,  # False for static library
        user_link_flags = linkopts,
    )
    link_env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        variables = link_variables,
    )
    link_flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        variables = link_variables,
    )

    # Extract the object files
    object_files = cc_compilation_outputs.object_files(use_pic = False)

    # Run linker
    args = ctx.actions.args()
    args.add_all(link_flags)
    args.add_all(object_files)
    ctx.actions.run(
        outputs = [static_library],
        inputs = depset(
            items = object_files,
            transitive = [ctx.attr._cc_toolchain.files],
        ),
        executable = link_tool,
        arguments = [args],
        mnemonic = "StaticLink",
        progress_message = "Linking generated C++",
        env = link_env,
    )

    # Build the linking info provider
    linking_context = cc_common.create_linking_context(
        libraries_to_link = [
            cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = static_library,
            ),
        ],
        user_link_flags = linkopts,
    )

    # Merge linking info for downstream rules
    linking_contexts.append(linking_context)
    cc_infos = [CcInfo(linking_context = linking_context) for linking_context in linking_contexts]
    merged_cc_info = cc_common.merge_cc_infos(
        cc_infos = cc_infos,
    )

    # Workaround to emulate CcLinkingInfo (the return value of cc_common.link)
    return struct(
        linking_context = merged_cc_info.linking_context,
        cc_linking_outputs = struct(
            static_libraries = [static_library],
        ),
    )

def _cc_compile_and_link_static_library(ctx, srcs, hdrs, deps, defines = []):
    """Compile and link C++ source into a static library"""
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    # Workaround since defines isn't an arg of cc_common.compile
    compilation_contexts = [dep[CcInfo].compilation_context for dep in deps]
    if defines:
        compilation_contexts.append(cc_common.create_compilation_context(
            defines = depset(defines),
        ))

    compilation_info = cc_common.compile(
        ctx = ctx,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = srcs,
        hdrs = hdrs,
        compilation_contexts = compilation_contexts,
    )

    # Custom link command
    # Workaround for https://github.com/bazelbuild/bazel/issues/6309
    # This should be replaced by cc_common.link() when api is fixed
    linking_info = _link_static_library(
        cc_compilation_outputs = compilation_info.cc_compilation_outputs,
        cc_toolchain = cc_toolchain,
        ctx = ctx,
        feature_configuration = feature_configuration,
        linking_contexts = [dep[CcInfo].linking_context for dep in deps],
    )

    return [
        DefaultInfo(files = depset(linking_info.cc_linking_outputs.static_libraries)),
        CcInfo(
            compilation_context = compilation_info.compilation_context,
            linking_context = linking_info.linking_context,
        ),
    ]

def _only_cc(f):
    """Filter for just C++ files/headers"""
    if f.extension in ["cpp", "h"]:
        return f.path
    return None

def _cc_sv_library_verilator_impl(ctx):
    """Produce a static library and C++ header files from a Verilog library"""

    # Gather all the Verilog source files, including transitive dependencies
    srcs = get_transitive_sources(
        ctx.files.srcs + ctx.files.hdrs,
        ctx.attr.deps,
    )

    # Default Verilator output prefix (e.g. "Vtop")
    prefix = ctx.attr.prefix + ctx.attr.top

    # Output directories/files
    verilator_output = ctx.actions.declare_directory(prefix + "-gen")
    verilator_output_cpp = ctx.actions.declare_directory(prefix)

    # Run Verilator
    args = ctx.actions.args()
    args.add("--cc")
    args.add("--Mdir", verilator_output.path)
    args.add("--prefix", prefix)
    args.add("--top-module", ctx.attr.top)
    if ctx.attr.trace:
        args.add("--trace")
    args.add_all(srcs)
    args.add_all(ctx.attr.vopts, expand_directories = False)
    ctx.actions.run(
        arguments = [args],
        executable = ctx.executable._verilator,
        inputs = srcs,
        outputs = [verilator_output],
        progress_message = "(Verilator) Compiling {}".format(ctx.label),
    )

    # Extract out just C++ files
    args = ctx.actions.args()
    args.add_all([verilator_output], map_each = _only_cc)
    ctx.actions.run_shell(
        arguments = [args],
        command = "mkdir -p {out} && cp $* {out}".format(out = verilator_output_cpp.path),
        inputs = [verilator_output],
        outputs = [verilator_output_cpp],
        progress_message = "(Verilator) Extracting C++ files",
    )

    # Collect the verilator ouput and, if needed, generate a driver program
    srcs = [verilator_output_cpp]
    hdrs = [verilator_output_cpp]
    if ctx.attr.include_main:
        driver = ctx.actions.declare_file(prefix + "_driver.cpp")
        ctx.actions.expand_template(
            template = ctx.file._main,
            output = driver,
            substitutions = {
                "{{Vtop}}": prefix,
            },
        )
        srcs.append(driver)

    # Do actual compile
    defines = ["VM_TRACE"] if ctx.attr.trace else []
    return _cc_compile_and_link_static_library(
        ctx,
        srcs = srcs,
        hdrs = hdrs,
        defines = defines,
        deps = ctx.attr._verilator_deps,
    )

cc_sv_library_verilator = rule(
    attrs = {
        "srcs": attr.label_list(
            doc = "List of verilog source files",
            mandatory = False,
            allow_files = [
                ".v",
                ".sv",
            ],
        ),
        "hdrs": attr.label_list(
            doc = "List of verilog header files",
            allow_files = [
                ".v",
                ".sv",
                ".vh",
                ".svh",
            ],
        ),
        "deps": attr.label_list(
            doc = "List of verilog and C++ dependencies",
        ),
        "top": attr.string(
            doc = "Top level module",
            mandatory = True,
        ),
        "trace": attr.bool(
            doc = "Enable tracing for Verilator",
            default = False,
        ),
        "prefix": attr.string(
            doc = "Prefix for generated C++ headers and classes",
            default = "V",
        ),
        "vopts": attr.string_list(doc = "Additional command line options to pass to Verilator"),
        "include_main": attr.bool(
            doc = "Generate a top level driver",
            default = False,
        ),
        "_verilator": attr.label(
            default = Label("@verilator//:verilator_bin"),
            cfg = "host",
            allow_single_file = True,
            executable = True,
        ),
        "_verilator_deps": attr.label_list(
            default = [
                Label("@verilator//:svdpi"),
                Label("@verilator//:libverilator"),
            ],
        ),
        "_main": attr.label(
            default = Label("@//tools/verilator:testbench.cpp"),
            allow_single_file = True,
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    fragments = ["cpp"],
    implementation = _cc_sv_library_verilator_impl,
)

def sv_test_verilator(
        name,
        top,
        srcs = [],
        hdrs = [],
        trace = True,
        deps = []):
    """Generate a top level testbench using Verilator"""
    if srcs == [] and hdrs == [] and deps == []:
        fail("srcs, hdrs, and deps cannot all be empty")

    gen_name = name + "_gen_cc"
    cc_sv_library_verilator(
        name = gen_name,
        srcs = srcs,
        hdrs = hdrs,
        include_main = True,
        top = top,
        trace = trace,
        vopts = ["-O3", "--assert"],
        deps = deps,
    )

    native.cc_test(
        name = name,
        srcs = [":" + gen_name],
        deps = [
            "@verilator//:svdpi",
            "@verilator//:libverilator",
        ],
    )
