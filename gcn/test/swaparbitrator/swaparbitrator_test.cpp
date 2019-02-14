#include <cstdint>
#include <iostream>
#include <array>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/Vswaparbitrator/Vswaparbitrator.h"

using ::testing::ElementsAre;

/// Testing class
class swaparbitratorTest : public ::testing::Test {
  protected:
    VerilatorDUT<Vswaparbitrator> dut;
    
    void TearDown() override {
      dut.finish();
    }
};


// TODO: Implement
TEST_F(swaparbitratorTest, Read) {
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
