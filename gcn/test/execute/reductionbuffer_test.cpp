#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/execute/Vreductionbuffer/Vreductionbuffer.h"

class ReductionBufferTest : public ::testing::Test {
  protected:
    VerilatorDUT<Vreductionbuffer> dut;

    void TearDown() override { dut.finish(); }
};

TEST_F(ReductionBufferTest, Simple) {
  dut.reset();
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  // Global verilator setup
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  Verilated::debug(0);
  Verilated::randReset(0);

  return RUN_ALL_TESTS();
}
