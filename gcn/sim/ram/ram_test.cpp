#include <random>

#include "absl/container/flat_hash_map.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "gcn/sim/ram/ram.h"
#include "gcn/sim/ram/Vram/Vram.h"

#include "gcn/test/verilator_driver.h"

TEST(Readmemh, Empty) {
  Ram ram(32, 32);
  std::stringstream ss("");
  EXPECT_EQ(ram.readmemh(ss), 0);
}

TEST(Readmemh, CommentSimple) {
  Ram ram(32, 32);
  std::stringstream ss("//comment");
  EXPECT_EQ(ram.readmemh(ss), 0);
}

TEST(Readmemh, ReadComments) {
  Ram ram(32, 32);
  std::stringstream ss("1 2 3//comment\n4");
  EXPECT_EQ(ram.readmemh(ss), 0);
  uint32_t v;
  ram.read(0, &v);
  EXPECT_EQ(v, 1);
  ram.read(1, &v);
  EXPECT_EQ(v, 2);
  ram.read(2, &v);
  EXPECT_EQ(v, 3);
  ram.read(3, &v);
  EXPECT_EQ(v, 4);
}

TEST(Readmemh, ReadHex) {
  Ram ram(32, 32);
  std::stringstream ss("0 1 2 3 4 5 6 7 8 9 A B C D E F");
  EXPECT_EQ(ram.readmemh(ss), 0);
  for (int i = 0; i < 16; i++) {
    uint32_t v;
    ram.read(i, &v);
    EXPECT_EQ(v, i);
  }
}

TEST(Readmemh, ReadHexLowercase) {
  Ram ram(32, 32);
  std::stringstream ss("0 1 2 3 4 5 6 7 8 9 a b c d e f");
  EXPECT_EQ(ram.readmemh(ss), 0);
  for (int i = 0; i < 16; i++) {
    uint32_t v;
    ram.read(i, &v);
    EXPECT_EQ(v, i);
  }
}

TEST(Readmemh, BadCharacter) {
  Ram ram(32, 32);
  std::stringstream ss("0 X");
  EXPECT_NE(ram.readmemh(ss), 0);
}

TEST(Readmemh, ExtraSpaces) {
  Ram ram(32, 32);
  std::stringstream ss("1\n\n\n\n2\n\n\t    3\n\n4\n\n\n\n");
  EXPECT_EQ(ram.readmemh(ss), 0);
  for (std::size_t i = 0; i < 4; i++) {
    uint32_t v;
    ram.read(i, &v);
    EXPECT_EQ(v, i + 1);
  }
}

TEST(Readmemh, AtAddress) {
  Ram ram(32, 32);
  std::stringstream ss("@0 1 2 3 4\n\t@8 9 A B C\n   @4 5 6 7 8\n@B D E F 10");
  EXPECT_EQ(ram.readmemh(ss), 0);
  for (std::size_t i = 0; i < 4; i++) {
    uint32_t v;
    ram.read(i, &v);
    EXPECT_EQ(v, i + 1);
  }
}

TEST(Readmemh, BadAddress) {
  Ram ram(32, 32);
  std::stringstream ss("@@0 0");
  EXPECT_NE(ram.readmemh(ss), 0);
}

class RamTest : public ::testing::Test {
  protected:
    VerilatorDUT<Vram> dut;

    void set_address(uint32_t address, bool write) {
      dut.poke(&Vram::a_addr, address);
      dut.poke(&Vram::a_write, write);
      dut.poke(&Vram::a_valid, 1);
      dut.stepUntil(&Vram::a_ready, 1);
      dut.step();
      dut.poke(&Vram::a_valid, 0);
    }

    uint32_t read(uint32_t address) {
      set_address(address, false);
      dut.poke(&Vram::r_ready, 1);
      dut.stepUntil(&Vram::r_valid, 1);
      auto value = dut.peek(&Vram::r_data);
      dut.step();
      dut.poke(&Vram::r_ready, 0);
      return value;
    }

    void write(uint32_t address, uint32_t value) {
      set_address(address, true);
      dut.poke(&Vram::w_valid, 1);
      dut.poke(&Vram::w_data, value);
      dut.stepUntil(&Vram::w_ready, 1);
      dut.step();
      dut.poke(&Vram::w_valid, 0);
    }

    void SetUp() override {
      dut.reset();
      dut.poke(&Vram::a_valid, 0);
      dut.poke(&Vram::r_ready, 0);
      dut.poke(&Vram::w_valid, 0);
    }

    void TearDown() override {
      dut.finish();
    }
};

TEST_F(RamTest, ReadWriteSimple) {
  uint32_t addr = 10;
  uint32_t value = 1;
  write(addr, value);
  EXPECT_EQ(read(addr), value);
}

TEST_F(RamTest, ReadWriteRandom) {
  // Random number generator
  std::mt19937 gen(/*seed*/0);
  std::uniform_int_distribution<uint32_t> dist;

  // Model
  absl::flat_hash_map<uint32_t, uint32_t> map;

  // Perform some writes
  for (int i = 0; i < 1000; i = i + 1) {
    auto value = dist(gen);
    auto addr  = dist(gen);
    map[addr] = value;
    write(addr, value);
  }

  // Check the results
  for (auto&& [addr, value] : map) {
    EXPECT_EQ(read(addr), value);
  }
}
