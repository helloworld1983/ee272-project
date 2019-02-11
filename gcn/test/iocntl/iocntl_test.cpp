#include <cstdint>
#include <iostream>
#include <array>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/iocntl/Vtb/Vtb.h"
#include "gcn/sim/ram/ram.h"

using ::testing::ElementsAre;

/// Testing class
class IocntlTest : public ::testing::Test {
  protected:
    VerilatorDUT<Vtb> dut;

    /// A full DRAM burst
    using Burst = std::array<uint16_t, 8>;

    Burst read(uint32_t address) {
      dut.poke(&Vtb::rd_req, 1);
      dut.poke(&Vtb::rd_addr, address);
      dut.step();
      //dut.stepUntilTrue(&Vtb::rd_gnt);
      dut.poke(&Vtb::rd_req, 0);
      //dut.stepUntilTrue(&Vtb::rd_valid);
      return dut.peekArray(&Vtb::rd_data);
    }

    void write(uint32_t address, Burst burst) {
      dut.poke(&Vtb::wr_req, 1);
      dut.poke(&Vtb::wr_addr, address);
      dut.pokeArray(&Vtb::wr_data, burst);
      //dut.stepUntilTrue(&Vtb::wr_gnt);
      dut.step();
      dut.poke(&Vtb::wr_req, 0);
    }

    void TearDown() override {
      dut.finish();
    }
};


// TODO: This doesn't pass currently
TEST_F(IocntlTest, Read) {
  dut.reset();
  auto data = read(1);
  dut.step(3);
  EXPECT_THAT(data, ElementsAre(1, 0, 2, 0, 3, 0, 4, 0));
}

// TODO: This doesn't pass currently
TEST_F(IocntlTest, Write) {
  dut.reset();
  write(1, {1, 2, 3, 4, 5, 6, 7, 8});
  dut.step(3);
  //EXPECT_EQ(dut.top.tb->dram->memory[0][0], 0);
}

// TODO: This doesn't pass currently
TEST_F(IocntlTest, ReadWrite) {
  dut.reset();
  write(0, {1, 2, 3, 4, 5, 6, 7, 8});
  auto data = read(0);
  //EXPECT_THAT(data, ElementsAre(1, 2, 3, 4, 5, 6, 7, 8));
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
