package(default_visibility = ["//gcn/test:__subpackages__"])

load("//tools:verilog.bzl", "sv_library")

sv_library(
    name = "iocntl",
    srcs = ["iocntl.sv"],
)

sv_library(
    name = "mac4x4",
    srcs = ["mac4x4.sv"],
    deps = ["//gcn/lib/dp:KW_dblbuf"],
)

sv_library(
    name = "mac16x16",
    srcs = ["mac16x16.sv"],
    deps = [":mac4x4"],
)

sv_library(
    name = "reductionbuffer",
    srcs = ["reductionbuffer.sv"],
    deps = ["//gcn/lib/sram:KW_sram"],
)

sv_library(
    name = "execute",
    srcs = ["execute.sv"],
    deps = [
        ":mac16x16",
        ":reductionbuffer",
        "//gcn/lib/dp:KW_pipe_reg",
    ],
)

sv_library(
    name = "gb2execute_cntl",
    srcs = ["gb2execute_cntl.sv"],
)

sv_library(
    name = "globalbuffer",
    srcs = [
        "floparray.sv",
        "globalbuffer.sv",
    ],
    deps = ["//gcn/lib/sram:KW_sram"],
)

sv_library(
    name = "dram2gb_cntl",
    srcs = [
        "dram2gb_cntl.sv",
        "dram2gb_stcntl.sv",
    ],
)

sv_library(
    name = "swaparbitrator",
    srcs = ["swaparbitrator.sv"],
)

sv_library(
    name = "gcn",
    srcs = [
        "gcn.sv",
    ],
    deps = [
        ":dram2gb_cntl",
        ":execute",
        ":gb2execute_cntl",
        ":globalbuffer",
        ":iocntl",
        ":swaparbitrator",
    ],
)

sv_library(
    name = "gcn_backend",
    srcs = [
        "gcn_backend.sv",
    ],
    deps = [
        ":execute",
        ":globalbuffer",
    ],
)
