# A provider for verilog libraries
VerilogInfo = provider(fields = ["transitive_sources"])

def get_transitive_sources(srcs, deps):
    """Obtain the underlying source files for a target and it's transitive
    dependencies.

    Args:
      srcs: a list of source files
      deps: a list of targets that are the direct dependencies
    Returns:
      a collection of the transitive sources
    """
    return depset(
        direct = srcs,
        transitive = [dep[VerilogInfo].transitive_sources for dep in deps],
    )

def _sv_library(ctx):
    transitive_sources = get_transitive_sources(ctx.files.srcs, ctx.attr.deps)
    return [VerilogInfo(transitive_sources = transitive_sources)]

sv_library = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = [
                ".v",
                ".sv",
            ],
        ),
        "deps": attr.label_list(),
    },
    implementation = _sv_library,
)
