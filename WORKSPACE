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

new_git_repository(
    name = "eigen",
    build_file = "//third_party:eigen.BUILD",
    remote = "https://github.com/eigenteam/eigen-git-mirror.git",
    tag = "3.3.7",
)

verilator_archive(
    name = "verilator",
    build_file = "@//third_party:verilator.BUILD",
    sha256 = "d5cef6edd3bdb7754776d902daae7a7e5dd662baa7c7f895cb7028b1d6910cac",
    version = "4.008",
)

http_archive(
    name = "bazel_skylib",
    url = "https://github.com/bazelbuild/bazel-skylib/archive/0.5.0.tar.gz",
    sha256 = "b5f6abe419da897b7901f90cbab08af958b97a8f3575b0d3dd062ac7ce78541f",
    strip_prefix = "bazel-skylib-0.5.0"
)
