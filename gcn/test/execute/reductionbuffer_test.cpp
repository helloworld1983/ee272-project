#include <cstdint>
#include <cstring>
#include <numeric>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/execute/Vreductionbuffer/Vreductionbuffer.h"

class ReductionBufferTest : public ::testing::Test {
  protected:
    VerilatorDUT<Vreductionbuffer> dut;

    void swapBuffers() {
      dut.poke(&Vreductionbuffer::swap_n, 0);
      dut.step();
      dut.poke(&Vreductionbuffer::swap_n, 1);
    }

    void write(uint16_t (&data)[16], uint8_t addr) {
      dut.poke(&Vreductionbuffer::w_en_n, 0);
      dut.poke(&Vreductionbuffer::w_addr, addr);
      std::memcpy(dut.top.w_data, data, sizeof(uint16_t) * 16);
      dut.step();
      dut.poke(&Vreductionbuffer::w_en_n, 1);
    }

    void read(uint16_t (&data)[16], uint8_t addr) {
      dut.poke(&Vreductionbuffer::r_en_n, 0);
      dut.poke(&Vreductionbuffer::r_addr, addr);
      dut.step();
      dut.poke(&Vreductionbuffer::r_en_n, 1);
      std::memcpy(data, dut.top.r_data, sizeof(uint16_t) * 16);
    }

    void SetUp() override {
      dut.poke(&Vreductionbuffer::w_en_n, 1);
      dut.poke(&Vreductionbuffer::r_en_n, 1);
      dut.poke(&Vreductionbuffer::swap_n, 1);
      dut.reset();
    }

    void TearDown() override { dut.finish(); }
};

TEST_F(ReductionBufferTest, Write0Read0) {
  // set to 0, 1, 2, ..., 15
  uint16_t data[16];
  std::iota(data, data + 16, 0);
  write(data, 0);
  swapBuffers();
  read(data, 0);
  for (int i = 0; i < 16; i++) {
    EXPECT_EQ(data[i], i);
  }
}

TEST_F(ReductionBufferTest, WriteAllReadAll) {
  uint16_t data[16];

  // Do a bunch of writes
  for (int i = 0; i < 256; i++) {
    std::iota(data, data + 16, 16 * i);
    write(data, i);
  }

  swapBuffers();

  for (int i = 0; i < 256; i++) {
    read(data, i);
    for (int j = 0; j < 16; j++) {
      EXPECT_EQ(data[j], i * 16 + j);
    }
  }
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
