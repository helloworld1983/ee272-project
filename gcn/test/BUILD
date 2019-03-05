package(default_visibility = ["//gcn/test:__subpackages__"])

load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_library(
    name = "verilator_driver",
    hdrs = ["verilator_driver.h"],
    visibility = ["//gcn:__subpackages__"],
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
    name = "execute_test",
    srcs = ["execute_test.cpp"],
    data = [
        "testvectors/data.txt",
    ],
    deps = [
        ":execute",
        ":verilator_driver",
        "@com_github_google_googletest//:gtest",
        "@eigen",
    ],
)
