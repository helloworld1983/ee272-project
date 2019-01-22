EE272 Project - Graph Neural Network Accelerator
---
Ann Wu, Kevin Kiningham

## Build Instructions

Staal uses the [Bazel](https://bazel.build/) build system.
If you do not already have Bazel installed, follow the [installation instructions](https://docs.bazel.build/versions/master/install.html).

### Running the tests

To run a specific test (e.g. the regression tests for iocntl):

```bash
$ bazel test //gcn/test:iocntl_test
```

To run all tests:

```bash
$ bazel test //gcn/test:*
```

To list all defined tests:

```bash
$ bazel query 'tests(//gcn/test:*)'
```
