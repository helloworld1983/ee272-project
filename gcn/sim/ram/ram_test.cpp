#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "gcn/sim/ram/ram.h"
#include "gcn/sim/ram/Vram/Vram.h"
//#include "gcn/test/verilator_wrapper.h"

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

TEST(Ram, ReadWrite) {
  Vram ram;
  ram.clock   = 0;
  ram.reset_n = 0;
  ram.eval();
  ram.clock   = 1;
  ram.eval();
}
