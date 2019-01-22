#include <cstdint>
#include <iostream>
#include <array>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/Viocntl/Viocntl.h"

using ::testing::ElementsAre;

/// Testing class
class IocntlTest : public ::testing::Test {
  protected:
    VerilatorDUT<Viocntl> dut;

    void reset() {
      dut.poke(&Viocntl::clock, 0);
      dut.poke(&Viocntl::reset_n, 0);
      dut.step(21);
      dut.poke(&Viocntl::reset_n, 1);
    }

    std::array<uint16_t, 8> read(uint32_t address) {
      dut.poke(&Viocntl::rd_req, 1);
      dut.poke(&Viocntl::rd_addr, address);
      while (!dut.peek(&Viocntl::rd_gnt)) {
        dut.step(10);
      }
      while (!dut.peek(&Viocntl::rd_valid)) {
        dut.step(10);
      }
      std::array<uint32_t, 4> data = dut.peekArray(&Viocntl::rd_data);
      return {
        static_cast<uint16_t>(data[0] & 0x00FF), static_cast<uint16_t>(data[0] & 0xFF00),
        static_cast<uint16_t>(data[1] & 0x00FF), static_cast<uint16_t>(data[1] & 0xFF00),
        static_cast<uint16_t>(data[2] & 0x00FF), static_cast<uint16_t>(data[2] & 0xFF00),
        static_cast<uint16_t>(data[3] & 0x00FF), static_cast<uint16_t>(data[3] & 0xFF00),
      };
    }
};

TEST_F(IocntlTest, Read) {
  reset();
  auto value = read(0);
  EXPECT_THAT(value, ElementsAre(0, 0, 0, 0, 0, 0, 0, 0));
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  // Global verilator setup
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(false);
  Verilated::debug(0);
  Verilated::randReset(0);

  return RUN_ALL_TESTS();
}
