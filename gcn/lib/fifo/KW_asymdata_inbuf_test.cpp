#include <cstdint>
#include <iostream>

#include "absl/types/optional.h"
#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/lib/fifo/VKW_asymdata_inbuf/VKW_asymdata_inbuf.h"

#include "gcn/test/verilator_driver.h"

using ::testing::Optional;
using ::testing::Eq;

class AsymdataTest : public ::testing::Test {
  protected:
    VerilatorDUT<VKW_asymdata_inbuf> dut;

    absl::optional<uint32_t> push(uint8_t data, bool flush = false) {
      absl::optional<uint32_t> ret;
      dut.poke(&VKW_asymdata_inbuf::push_req_n, 0);
      dut.poke(&VKW_asymdata_inbuf::flush_n, !flush);
      dut.poke(&VKW_asymdata_inbuf::data_in, data);
      dut.eval(); // Needed to evaluate combinational logic
      if (!dut.peek(&VKW_asymdata_inbuf::push_wd_n)) {
        ret = dut.peek(&VKW_asymdata_inbuf::data_out);
      }
      dut.step();
      dut.poke(&VKW_asymdata_inbuf::push_req_n, 1);
      return ret;
    }

    void SetUp() override {
      dut.poke(&VKW_asymdata_inbuf::push_req_n, 1);
      dut.poke(&VKW_asymdata_inbuf::flush_n, 1);
      dut.poke(&VKW_asymdata_inbuf::fifo_full, 0);
      dut.reset();
    }

    void TearDown() override {
      dut.finish();
    }
};

TEST_F(AsymdataTest, Simple) {
  EXPECT_THAT(push(1), Eq(absl::nullopt));
  EXPECT_THAT(push(2), Eq(absl::nullopt));
  EXPECT_THAT(push(3), Eq(absl::nullopt));
  EXPECT_THAT(push(4), Eq(0x01020304));
  EXPECT_THAT(push(5), Eq(absl::nullopt));
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
