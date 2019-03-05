workspace(name = "gcn")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository", "new_git_repository")
load("@gcn//tools/verilator:defs.bzl", "verilator_archive")

git_repository(
    name = "com_github_google_googletest",
    remote = "https://github.com/google/googletest.git",
    tag = "release-1.8.1",
)

git_repository(
    name = "com_github_gflags_gflags",
    remote = "https://github.com/gflags/gflags.git",
    tag = "v2.2.2",
)

http_archive(
    name = "com_github_google_benchmark",
    sha256 = "59f918c8ccd4d74b6ac43484467b500f1d64b40cc1010daa055375b322a43ba3",
    strip_prefix = "benchmark-16703ff83c1ae6d53e5155df3bb3ab0bc96083be",
    urls = ["https://github.com/google/benchmark/archive/16703ff83c1ae6d53e5155df3bb3ab0bc96083be.zip"],
)

git_repository(
    name = "com_github_abseil_abseil-cpp",
    commit = "d78310fe5a82f2e0e6e16509ef8079c8d7e4674e",
    remote = "https://github.com/abseil/abseil-cpp.git",
)

new_git_repository(
    name = "eigen",
    build_file = "//third_party:eigen.BUILD",
    remote = "https://github.com/eigenteam/eigen-git-mirror.git",
    tag = "3.3.7",
)

verilator_archive(
    name = "verilator",
    build_file = "//third_party:verilator.BUILD",
    sha256 = "5651748fe28e373ebf7a6364f5e7935ec9b39d29671f683f366e99d5e157d571",
    version = "4.010",
)

http_archive(
    name = "bazel_skylib",
    sha256 = "2c62d8cd4ab1e65c08647eb4afe38f51591f43f7f0885e7769832fa137633dcb",
    strip_prefix = "bazel-skylib-0.7.0",
    url = "https://github.com/bazelbuild/bazel-skylib/archive/0.7.0.tar.gz",
)
