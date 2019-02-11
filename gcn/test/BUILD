package(default_visibility = ["//gcn/test:__subpackages__"])

load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_library(
    name = "verilator_driver",
    hdrs = ["verilator_driver.h"],
)

# Verilog models
cc_sv_library_verilator(
    name = "mac4x4",
    top = "mac4x4",
    trace = False,
    vopts = [
        "-O3",
        "--assert",
    ],
    deps = ["//gcn:mac4x4"],
)

cc_sv_library_verilator(
    name = "mac16x16",
    top = "mac16x16",
    trace = False,
    vopts = [
        "-O3",
        "--assert",
    ],
    deps = ["//gcn:mac16x16"],
)

cc_sv_library_verilator(
    name = "execute",
    srcs = [],
    top = "execute",
    trace = True,
    vopts = [
        "-O3",
        "--assert",
    ],
    deps = ["//gcn:execute"],
)


# Actual tests
cc_test(
    name = "mac4x4_test",
    srcs = ["mac4x4_test.cpp"],
    deps = [
        ":mac4x4",
        ":mac16x16",
        ":verilator_driver",
        "@com_github_google_googletest//:gtest",
        "@eigen//:eigen",
    ],
)

cc_test(
    name = "execute_test",
    srcs = ["execute_test.cpp"],
    deps = [
        ":execute",
        ":verilator_driver",
        "@com_github_google_googletest//:gtest",
        "@eigen//:eigen",
    ],
    data = [
        "testvectors/data.txt",
    ],
)
