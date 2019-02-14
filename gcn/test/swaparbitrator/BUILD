load("//tools/verilator:rules.bzl", "cc_sv_library_verilator")

cc_sv_library_verilator(
    name = "swaparbitrator",
    #srcs = ["swaparbitrator.sv"],
    top = "swaparbitrator",
    trace = True,
    vopts = ["--assert"],
    deps = [
        "//gcn:swaparbitrator",
    ],
)

cc_test(
    name = "swaparbitrator_test",
    srcs = ["swaparbitrator_test.cpp"],
    deps = [
        ":swaparbitrator",
        "//gcn/test:verilator_driver",
        "@com_github_google_googletest//:gtest",
    ],
)

