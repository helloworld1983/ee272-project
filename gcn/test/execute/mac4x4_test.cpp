#include <cassert>
#include <cstring>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "Eigen/Dense"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/execute/Vmac4x4/Vmac4x4.h"

using ::testing::ElementsAre;
using Vec4 = Eigen::Matrix<uint16_t, 4, 1>;
using Mat4 = Eigen::Matrix<uint16_t, 4, 4>;

void pokeVec4(QData* vec, const Vec4& data) {
  std::memcpy(vec, data.data(), sizeof(Vec4::Scalar) * data.size());
}

void peekVec4(Vec4& result, const QData* vec) {
  result = Vec4::Map(reinterpret_cast<const Vec4::Scalar*>(vec));
}

class Mac4x4Test : public ::testing::Test {
  protected:
    VerilatorDUT<Vmac4x4> dut;

    void SetUp() override { dut.reset(); }
    void TearDown() override { dut.finish(); }

    void swapBuffers() {
      dut.poke(&Vmac4x4::swap_n, 0);
      dut.step();
      dut.poke(&Vmac4x4::swap_n, 1);
    }

    void loadWeightArray(uint8_t col, uint8_t addr, const Vec4& w) {
      assert(col < 4 && "Invalid column");
      assert(addr < 32 && "Invalid index");
      pokeVec4(&dut.top.w_data, w);
      dut.poke(&Vmac4x4::w_col, col);
      dut.poke(&Vmac4x4::w_addr, addr);
      dut.poke(&Vmac4x4::w_en_n, 0);
      dut.poke(&Vmac4x4::r_en_n, 1);
      dut.poke(&Vmac4x4::swap_n, 1);
      dut.step();
    }

    void loadWeightMatrix(uint8_t addr, const Mat4& w) {
      for (int i = 0; i < 4; i++) {
        // Note: A column of the mac array corresponds to a row of the weight matrix
        // Since a column of the mac array is load each cycle, we load a row
        // of the weight matrix at a time
        loadWeightArray(i, addr, w.row(i));
      }
    }

    void gmv4(Vec4* result, uint8_t addr, const Vec4& a, const Vec4& c) {
      assert(addr < 32 && "Invalid index");
      dut.poke(&Vmac4x4::r_addr, addr);
      dut.poke(&Vmac4x4::w_en_n, 1);
      dut.poke(&Vmac4x4::r_en_n, 0);
      dut.poke(&Vmac4x4::swap_n, 1);
      pokeVec4(&dut.top.a, a);
      pokeVec4(&dut.top.c, c);
      dut.step();
      dut.poke(&Vmac4x4::r_en_n, 1);
      dut.step();
      peekVec4(*result, &dut.top.x);
    }
};

TEST_F(Mac4x4Test, Simple) {
  // Construct initial matrix
  Mat4 W = (Mat4() <<
     1,  2,  3,  4,
     5,  6,  7,  8,
     9, 10, 11, 12,
    13, 14, 15, 16
  ).finished();
  loadWeightMatrix(0, W);

  // Swap the read/write buffer
  swapBuffers();

  // Perform the multiplication
  Vec4 a{1, 2, 3, 4};
  Vec4 c{9, 9, 9, 9};
  Vec4 r;
  gmv4(&r, 0, a, c);

  // Expect equality
  EXPECT_EQ(r, W * a + c);
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
