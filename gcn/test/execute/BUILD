load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

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
    name = "reductionbuffer",
    top = "reductionbuffer",
    trace = False,
    vopts = [
        "-O3",
        "--assert",
    ],
    deps = ["//gcn:reductionbuffer"],
)

cc_sv_library_verilator(
    name = "execute",
    top = "execute",
    trace = False,
    vopts = [
        "-O3",
        "--assert",
    ],
    deps = ["//gcn:execute"],
)

cc_test(
    name = "mac4x4_test",
    srcs = ["mac4x4_test.cpp"],
    deps = [
        ":mac4x4",
        ":mac16x16",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
        "@eigen//:eigen",
    ],
)

cc_test(
    name = "reductionbuffer_test",
    srcs = ["reductionbuffer_test.cpp"],
    deps = [
        ":reductionbuffer",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)
