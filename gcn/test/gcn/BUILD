load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "gcn",
    #srcs = ["gcn.sv"],
    top = "gcn",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn",
    ],
)

cc_test(
    name = "gcn_test",
    srcs = ["gcn_test.cpp"],
    deps = [
        ":gcn",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)
