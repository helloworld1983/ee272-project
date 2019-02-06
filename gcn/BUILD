package(default_visibility = ["//gcn/test:__pkg__"])

load("@//tools:verilog.bzl", "sv_library")

sv_library(
    name = "iocntl",
    srcs = ["iocntl.sv"],
)

sv_library(
    name = "execute",
    srcs = ["execute.sv"],
)

sv_library(
    name = "mac4x4",
    srcs = ["mac4x4.sv"],
)

sv_library(
    name = "mac16x16",
    srcs = ["mac16x16.sv"],
    deps = [":mac4x4.sv"],
)

sv_library(
    name = "globalbuffer",
    srcs = [
        "globalbuffer.sv",
        "floparray.sv"
    ],
)
