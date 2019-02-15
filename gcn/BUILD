package(default_visibility = ["//gcn/test:__subpackages__"])

load("//tools:verilog.bzl", "sv_library")

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
    deps = [":mac4x4"],
)

sv_library(
    name = "globalbuffer",
    srcs = [
        "globalbuffer.sv",
        "floparray.sv",
    ],
)

sv_library(
    name = "dram2gb_cntl",
    srcs = [
        "dram2gb_cntl.sv",
    ],
)

sv_library(
    name = "swaparbitrator",
    srcs = [
        "swaparbitrator.sv",
    ],
)

sv_library(
    name = "gcn",
    srcs = [
        "gcn.sv",
        "globalbuffer.sv",
        "floparray.sv",
        "swaparbitrator.sv",
        "dram2gb_cntl.sv",
    ],
)
