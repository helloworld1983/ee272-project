load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

# Library for interfacing with Verilator models
cc_library(
    name = "verilator_driver",
    hdrs = ["verilator_driver.h"],
)

# Verilog models
cc_sv_library_verilator(
    name = "iocntl",
    srcs = ["dram.sv"],
    top = "tb",
    trace = True,
    vopts = ["--assert"],
    deps = ["//gcn:iocntl"],
)

# Actual tests
cc_test(
    name = "iocntl_test",
    srcs = ["iocntl_test.cpp"],
    deps = [
        ":iocntl",
        ":verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)

cc_test(
    name = "execute_test",
    srcs = ["execute_test.cpp"],
    deps = [
        ":verilator_driver",
        "@com_github_google_googletest//:gtest",
        "@eigen//:eigen",
    ],
)
