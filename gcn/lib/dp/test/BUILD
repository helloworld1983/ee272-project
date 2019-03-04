load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "KW_dblbuf_cc",
    srcs = ["KW_dblbuf_wrap.sv"],
    top = "KW_dblbuf_wrap",
    vopts = ["--assert"],
    deps = ["//gcn/lib/dp:KW_dblbuf"],
)
