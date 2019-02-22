load("//tools:verilog.bzl", "sv_library")
load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

sv_library(
    name = "SRAM1RW",
    srcs = glob(["sim/SRAM*.sv"]),
)

sv_library(
    name = "KW_sram",
    srcs = [
        "KW_ram_2rws_sram.sv",
        "KW_ram_1rws_sram.sv",
        "KW_ram_1ra_1ws_dff.sv",
    ],
    deps = [":SRAM1RW"],
    visibility = ["//gcn:__subpackages__"],
)

cc_sv_library_verilator(
    name = "KW_sram_cc",
    top = "KW_ram_1rws_sram",
    deps = [":KW_sram"],
)
