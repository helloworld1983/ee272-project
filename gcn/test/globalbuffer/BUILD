load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "globalbuffer",
    #srcs = ["globalbuffer.sv"],
    top = "globalbuffer",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn:globalbuffer",
    ],
)

cc_test(
    name = "globalbuffer_test",
    srcs = ["globalbuffer_test.cpp"],
    deps = [
        ":globalbuffer",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)
