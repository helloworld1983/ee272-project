load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "iocntl",
    srcs = [],
    top = "iocntl",
    trace = True,
    vopts = [
        "-O3",
        "--assert",
    ],
    deps = ["//gcn:iocntl"],
)

cc_library(
    name = "verilator_driver",
    hdrs = ["verilator_driver.h"],
)

cc_test(
    name = "iocntl_test",
    srcs = ["iocntl_test.cpp"],
    deps = [
        ":iocntl",
        ":verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)
