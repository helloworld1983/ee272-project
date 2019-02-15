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
    int sel_ = 0;

    void swapBuffers() {
      sel_ = !sel_;
    }

    void write(uint16_t (&data)[16]) {
      dut.poke(&Vreductionbuffer::sel, sel_);
      dut.poke(&Vreductionbuffer::wen, 1);
      std::memcpy(dut.top.wdata, data, sizeof(uint16_t) * 16);
      dut.step();
      dut.poke(&Vreductionbuffer::wen, 0);
    }

    void read(uint16_t (&data)[16]) {
      dut.poke(&Vreductionbuffer::sel, sel_);
      dut.poke(&Vreductionbuffer::ren, 1);
      dut.poke(&Vreductionbuffer::ridx, 0);
      dut.step();
      dut.poke(&Vreductionbuffer::ren, 0);
      std::memcpy(data, dut.top.rdata, sizeof(uint16_t) * 16);
    }

    void SetUp() override {
      dut.poke(&Vreductionbuffer::sel, sel_);
      dut.poke(&Vreductionbuffer::wen, 0);
      dut.poke(&Vreductionbuffer::ren, 0);
      dut.reset();
    }

    void TearDown() override { dut.finish(); }
};

TEST_F(ReductionBufferTest, Simple) {
  // set to 0, 1, 2, ..., 15
  uint16_t data[16];
  std::iota(data, data + 16, 0);

  // Do a bunch of writes
  for (int i = 0; i < 15; i++) {
    write(data);
  }

  swapBuffers();
  read(data);
  EXPECT_EQ(data[0], 0);
  EXPECT_EQ(data[1], 1);
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
