load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "dram2gb_cntl",
    #srcs = ["dram2gb_cntl.sv"],
    top = "dram2gb_cntl",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn:dram2gb_cntl",
    ],
)

cc_test(
    name = "dram2gb_cntl_test",
    srcs = ["dram2gb_cntl_test.cpp"],
    deps = [
        ":dram2gb_cntl",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)

