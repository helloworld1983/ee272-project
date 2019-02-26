load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "gb2execute_cntl",
    #srcs = ["gb2execute_cntl.sv"],
    top = "gb2execute_cntl",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn:gb2execute_cntl",
    ],
)

cc_test(
    name = "gb2execute_cntl_test",
    srcs = ["gb2execute_cntl_test.cpp"],
    deps = [
        ":gb2execute_cntl",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)

