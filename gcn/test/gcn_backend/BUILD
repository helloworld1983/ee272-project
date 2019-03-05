load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "gcn_backend",
    #srcs = ["gcn.sv"],
    top = "gcn_backend",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn:gcn_backend",
    ],
)

cc_test(
    name = "gcn_backend_test",
    srcs = ["gcn_backend_test.cpp"],
    deps = [
        ":gcn_backend",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)
