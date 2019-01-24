#include <cstdint>
#include <memory>

#include "Eigen/Dense"

#include "gtest/gtest.h"
#include "gmock/gmock.h"

using Matrix = Eigen::Matrix<uint16_t, Eigen::Dynamic, Eigen::Dynamic>;

// Test fixture:
// https://github.com/google/googletest/blob/master/googletest/docs/primer.md#test-fixtures-using-the-same-data-configuration-for-multiple-tests
class ExecuteTest : public ::testing::Test {
  protected:
    // TODO: Any common variables go here
};

TEST_F(ExecuteTest, FirstEigenTest) {
  // TODO: Put the test case here
  Matrix W(32, 10);
  Matrix A(32, 32);

  // List of assertions in GTest:
  // https://github.com/google/googletest/blob/master/googletest/docs/primer.md#basic-assertions
  ASSERT_EQ((W.transpose() * A).norm(), 0);
}

TEST_F(ExecuteTest, SecondEigenTest) {
  // TODO: Another test case
  ASSERT_LE(0, 1);
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  // Global verilator setup
  // Verilated::commandArgs(argc, argv);
  // Verilated::traceEverOn(false);
  // Verilated::debug(0);
  // Verilated::randReset(0);

  return RUN_ALL_TESTS();
}
