load("//tools:verilog.bzl", "sv_library")
load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

sv_library(
    name = "KW_dblbuf",
    srcs = [
        "KW_dblbuf.sv",
        "KW_dblbuf_cntl.sv",
    ],
    deps = ["//gcn/lib/sram:KW_sram"],
    visibility = ["//gcn:__subpackages__"],
)

sv_library(
    name = "KW_pipe_reg",
    srcs = ["KW_pipe_reg.sv"],
    visibility = ["//gcn:__subpackages__"],
)

cc_sv_library_verilator(
    name = "KW_dblbuf_cc",
    top = "KW_dblbuf",
    vopts = ["--assert"],
    deps = [":KW_dblbuf"],
)
