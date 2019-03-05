load("//tools:verilog.bzl", "sv_library")

sv_library(
    name = "SRAM1RW",
    srcs = glob(["sim/SRAM*.sv"]),
)

sv_library(
    name = "KW_sram",
    srcs = [
        "KW_ram_1ra_1ws_dff.sv",
        "KW_ram_1rws_dff.sv",
        "KW_ram_1rws_sram.sv",
        "KW_ram_2rws_sram.sv",
    ],
    visibility = ["//gcn:__subpackages__"],
    deps = [":SRAM1RW"],
)
