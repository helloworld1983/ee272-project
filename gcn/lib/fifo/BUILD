load("//tools:verilog.bzl", "sv_library")
load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

sv_library(
    name = "KW_fifo",
    srcs = [
        "KW_asymdata_inbuf.sv",
        "KW_fifo.sv",
    ],
    visibility = ["//gcn:__subpackages__"],
)

cc_sv_library_verilator(
    name = "KW_asymfifo_s1_sf_cc",
    top = "KW_asymfifo_s1_sf",
    vopts = ["--assert"],
    deps = [":KW_fifo"],
)

cc_test(
    name = "KW_fifo_test",
    srcs = ["KW_fifo_test.cpp"],
    deps = [
        ":KW_asymfifo_s1_sf_cc",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)

cc_sv_library_verilator(
    name = "KW_asymdata_inbuf_cc",
    top = "KW_asymdata_inbuf",
    vopts = ["--assert"],
    deps = [":KW_fifo"],
)

cc_test(
    name = "KW_asymdata_inbuf_test",
    srcs = ["KW_asymdata_inbuf_test.cpp"],
    deps = [
        ":KW_asymdata_inbuf_cc",
        "//gcn/test:verilator_driver",
        "@com_github_abseil_abseil-cpp//absl/types:optional",
        "@com_github_google_googletest//:gtest",
    ],
)
