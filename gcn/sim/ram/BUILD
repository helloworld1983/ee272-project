load("//tools:verilog.bzl", "sv_library")
load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

sv_library(
    name = "ram",
    srcs = ["ram.sv"],
    visibility = ["//gcn:__subpackages__"],
)

cc_library(
    name = "ram_dpi",
    srcs = [
        "ram_dpi.cpp",
        "ram.cpp",
    ],
    hdrs = ["ram.h"],
    deps = [
        "@com_github_abseil_abseil-cpp//absl/container:flat_hash_map",
        "@verilator//:svdpi",
    ],
    visibility = ["//gcn:__subpackages__"],
)

cc_sv_library_verilator(
    name = "ram_cc_sv",
    top = "ram",
    trace = True,
    vopts = ["--assert"],
    deps = [":ram"],
)


cc_test(
    name = "ram_test",
    srcs = ["ram_test.cpp"],
    deps = [
        ":ram_dpi",
        ":ram_cc_sv",
        "@com_github_google_googletest//:gtest",
        "@com_github_google_googletest//:gtest_main",
    ],
)
