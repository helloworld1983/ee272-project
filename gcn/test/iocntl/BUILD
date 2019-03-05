load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "iocntl",
    srcs = ["iocntl_test.sv"],
    top = "tb",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn:iocntl",
        "//gcn/sim/ram",
    ],
)

cc_test(
    name = "iocntl_test",
    srcs = ["iocntl_test.cpp"],
    deps = [
        ":iocntl",
        "//gcn/sim/ram:ram_dpi",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)
