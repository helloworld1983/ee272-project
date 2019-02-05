#include <cassert>
#include <cstring>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "Eigen/Dense"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/Vmac4x4/Vmac4x4.h"

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
    // Which buffer to read/write to
    // 0 means we READ from buffer 0 and WRITE to buffer 1
    uint8_t sel = 0;

    void SetUp() override { dut.reset(); }
    void TearDown() override { dut.finish(); }

    void swapBuffers() { sel = !sel; }

    void loadWeightArray(uint8_t col, uint8_t idx, const Vec4& w) {
      assert(col < 4 && "Invalid column");
      assert(idx < 32 && "Invalid index");
      pokeVec4(&dut.top.wb, w);
      dut.poke(&Vmac4x4::wbcol, col);
      dut.poke(&Vmac4x4::wbidx, idx);
      dut.poke(&Vmac4x4::wen, 1);
      dut.poke(&Vmac4x4::ren, 0);
      dut.poke(&Vmac4x4::sel, sel);
      dut.step();
    }

    void loadWeightMatrix(uint8_t idx, const Mat4& w) {
      for (int i = 0; i < 4; i++) {
        // Note: A column of the mac array corresponds to a row of the weight matrix
        // Since a column of the mac array is load each cycle, we load a row
        // of the weight matrix at a time
        loadWeightArray(i, idx, w.row(i));
      }
    }

    void gmv4(Vec4* result, uint8_t idx, const Vec4& a, const Vec4& c) {
      assert(idx < 32 && "Invalid index");
      dut.poke(&Vmac4x4::rbidx, idx);
      dut.poke(&Vmac4x4::wen, 0);
      dut.poke(&Vmac4x4::ren, 1);
      dut.poke(&Vmac4x4::sel, sel);
      pokeVec4(&dut.top.a, a);
      pokeVec4(&dut.top.c, c);
      dut.step();
      dut.poke(&Vmac4x4::ren, 0);
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
