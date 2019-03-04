load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "KW_sram_cc",
    srcs = ["KW_ram_1rws_sram_wrap.sv"],
    top = "KW_ram_1rws_sram_wrap",
    deps = ["//gcn/lib/sram:KW_sram"],
)

cc_sv_library_verilator(
    name = "KW_dff_cc",
    srcs = ["KW_ram_1rws_dff_wrap.sv"],
    top = "KW_ram_1rws_dff_wrap",
    deps = ["//gcn/lib/sram:KW_sram"],
)
