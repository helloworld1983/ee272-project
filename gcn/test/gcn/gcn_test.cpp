#include <cstdint>
#include <iostream>
#include <array>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/Vgcn/Vgcn.h"

using ::testing::ElementsAre;

/// Testing class
class gcnTest : public ::testing::Test {
  protected:
    VerilatorDUT<Vgcn> dut;
    
    void TearDown() override {
      dut.finish();
    }
};


// TODO: Implement
TEST_F(gcnTest, Read) {
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
