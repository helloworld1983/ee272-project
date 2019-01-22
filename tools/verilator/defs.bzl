"""Workspace definitions for Verilator rules"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# TODO(kkiningh): Should add support for using the local install
def verilator_archive(name, build_file, sha256, version):
    urls = ["https://www.veripool.org/ftp/verilator-{version}.tgz".format(version = version)]
    strip_prefix = "verilator-" + version
    http_archive(
        name = name,
        build_file = build_file,
        sha256 = sha256,
        strip_prefix = strip_prefix,
        urls = urls,
    )
