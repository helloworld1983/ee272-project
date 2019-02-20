#include <cstdint>
#include <queue>
#include <random>

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/lib/fifo/VKW_asymfifo_s1_sf/VKW_asymfifo_s1_sf.h"

#include "gcn/test/verilator_driver.h"

struct Flags {
  bool empty;
  bool almost_empty;
  bool half_full;
  bool almost_full;
  bool full;
  bool error;

  bool operator==(const Flags& flags) const {
    return (empty == flags.empty &&
      almost_empty == flags.almost_empty &&
      half_full == flags.half_full &&
      almost_full == flags.almost_full &&
      full == flags.full &&
      error == flags.error);
  }

  friend std::ostream& operator<<(std::ostream& os, const Flags& flags) {
    return os << "{"
      << " empty: " << flags.empty
      << " almost_empty: " << flags.almost_empty
      << " half_full: " << flags.half_full
      << " almost_full: " << flags.almost_full
      << " full: " << flags.full
      << " error: " << flags.error
      << " }";
  }
};

class FifoModel {
  std::queue<uint32_t> queue_;
  int depth_ = 16;
  int af_level_ = 1;
  int ae_level_ = 1;
  bool error_ = false;

public:
  void reset() {
    auto tmp = std::queue<uint32_t>();
    queue_.swap(tmp);
    error_ = false;
  }

  void push(uint32_t value) {
    if (full()) {
      error_ = true;
    }
    queue_.push(value);
  }

  uint32_t pop() {
    if (empty()) {
      error_ = true;
      return 0;
    }
    auto value = queue_.front();
    queue_.pop();
    return value;
  }

  uint32_t pushAndPop(uint32_t value) {
    if (empty()) {
      error_ = true;
      return 0;
    }
    auto ret = queue_.front();
    queue_.pop();
    queue_.push(value);
    return ret;
  }

  // Flags
  bool empty() const { return queue_.empty(); }
  bool almostEmpty() const { return queue_.size() <= ae_level_; }
  bool halfFull() const { return queue_.size() >= depth_ / 2; }
  bool almostFull() const { return queue_.size() >= (depth_ - af_level_); }
  bool full() const { return queue_.size() == depth_; }
  bool error() const { return error_; }

  Flags flags() {
    return Flags{ empty(), almostEmpty(), halfFull(), almostFull(), full(), error() };
  }
};

class FifoTest : public ::testing::Test {
  protected:
    VerilatorDUT<VKW_asymfifo_s1_sf> dut;

    void push(uint32_t value) {
      dut.poke(&VKW_asymfifo_s1_sf::push_req_n, 0);
      dut.poke(&VKW_asymfifo_s1_sf::data_in, value);
      dut.step();
      dut.poke(&VKW_asymfifo_s1_sf::push_req_n, 1);
    }

    uint32_t pop() {
      dut.poke(&VKW_asymfifo_s1_sf::pop_req_n, 0);
      dut.step();
      dut.poke(&VKW_asymfifo_s1_sf::pop_req_n, 1);
      return dut.peek(&VKW_asymfifo_s1_sf::data_out);
    }

    uint32_t pushAndPop(uint32_t value) {
      dut.poke(&VKW_asymfifo_s1_sf::push_req_n, 0);
      dut.poke(&VKW_asymfifo_s1_sf::pop_req_n, 0);
      dut.poke(&VKW_asymfifo_s1_sf::data_in, value);
      dut.step();
      dut.poke(&VKW_asymfifo_s1_sf::push_req_n, 1);
      dut.poke(&VKW_asymfifo_s1_sf::pop_req_n, 1);
      return dut.peek(&VKW_asymfifo_s1_sf::data_out);
    }

    // Flags
    bool empty() { return dut.peek(&VKW_asymfifo_s1_sf::empty); }
    bool almostEmpty() { return dut.peek(&VKW_asymfifo_s1_sf::almost_empty); }
    bool halfFull() { return dut.peek(&VKW_asymfifo_s1_sf::half_full); }
    bool almostFull() { return dut.peek(&VKW_asymfifo_s1_sf::almost_full); }
    bool full() { return dut.peek(&VKW_asymfifo_s1_sf::full); }
    bool error() { return dut.peek(&VKW_asymfifo_s1_sf::error); }

    Flags flags() {
      return Flags{ empty(), almostEmpty(), halfFull(), almostFull(), full(), error() };
    }

    void SetUp() override {
      dut.poke(&VKW_asymfifo_s1_sf::push_req_n, 1);
      dut.poke(&VKW_asymfifo_s1_sf::pop_req_n, 1);
      dut.poke(&VKW_asymfifo_s1_sf::flush_n, 1);
      dut.reset();
    }

    void TearDown() override {
      dut.finish();
    }
};

// Same as FifoTest, but starting with the Fifo full
class FifoTestFull : public FifoTest {
  protected:
    void SetUp() override {
      dut.poke(&VKW_asymfifo_s1_sf::push_req_n, 1);
      dut.poke(&VKW_asymfifo_s1_sf::pop_req_n, 1);
      dut.poke(&VKW_asymfifo_s1_sf::flush_n, 1);
      dut.reset();
      for (uint32_t i = 0; i < 16; i++) {
        push(i + 1);
      }
    }
};

TEST_F(FifoTest, FlagsEmpty) {
  EXPECT_TRUE(empty());
  EXPECT_TRUE(almostEmpty());
  EXPECT_FALSE(halfFull());
  EXPECT_FALSE(almostFull());
  EXPECT_FALSE(full());
  EXPECT_FALSE(error());
}

TEST_F(FifoTestFull, FlagsFull) {
  EXPECT_FALSE(empty());
  EXPECT_FALSE(almostEmpty());
  EXPECT_TRUE(halfFull());
  EXPECT_TRUE(almostFull());
  EXPECT_TRUE(full());
  EXPECT_FALSE(error());
}

TEST_F(FifoTestFull, FlagsReset) {
  dut.reset();
  EXPECT_TRUE(empty());
  EXPECT_TRUE(almostEmpty());
  EXPECT_FALSE(halfFull());
  EXPECT_FALSE(almostFull());
  EXPECT_FALSE(full());
  EXPECT_FALSE(error());
}

TEST_F(FifoTest, PushSingle) {
  push(1);
  EXPECT_FALSE(error());
}

TEST_F(FifoTestFull, PopSingle) {
  pop();
  EXPECT_FALSE(error());
}

TEST_F(FifoTest, ErrorPopEmpty) {
  pop();
  EXPECT_TRUE(error());
}

TEST_F(FifoTestFull, ErrorPushFull) {
  push(17);
  EXPECT_TRUE(error());
}

TEST_F(FifoTest, ErrorPushAndPopEmpty) {
  EXPECT_TRUE(empty());
  pushAndPop(1);
  EXPECT_TRUE(error());
}

TEST_F(FifoTestFull, PushAndPopFull) {
  EXPECT_TRUE(full());
  EXPECT_EQ(pushAndPop(17), 1);
  EXPECT_FALSE(error());
  EXPECT_TRUE(full());
}

TEST_F(FifoTest, PushPopSingle) {
  EXPECT_TRUE(empty());
  push(1);
  EXPECT_FALSE(empty());
  EXPECT_EQ(pop(), 1);
  EXPECT_FALSE(error());
  EXPECT_TRUE(empty());
}

TEST_F(FifoTestFull, PopPushSingle) {
  EXPECT_TRUE(full());
  EXPECT_EQ(pop(), 1);
  EXPECT_FALSE(full());
  push(17);
  EXPECT_FALSE(error());
  EXPECT_TRUE(full());
}

TEST_F(FifoTest, PushFullPopEmpty) {
  EXPECT_TRUE(empty());
  EXPECT_FALSE(error());
  for (uint32_t i = 0; i < 16; i++) {
    push(i + 1);
    EXPECT_FALSE(error());
  }
  EXPECT_TRUE(full());
  for (uint32_t i = 0; i < 16; i++) {
    EXPECT_EQ(pop(), i + 1);
    EXPECT_FALSE(error());
  }
  EXPECT_TRUE(empty());
}

TEST_F(FifoTest, PushFullPopEmptyMany) {
  for (uint32_t i = 0; i < 4; i++) {
    EXPECT_TRUE(empty());
    for (uint32_t j = 0; j < 16; j++) {
      push(256 * i + j + 1);
      EXPECT_FALSE(error());
    }
    EXPECT_TRUE(full());
    for (uint32_t j = 0; j < 16; j++) {
      EXPECT_EQ(pop(), 256 * i + j + 1);
      EXPECT_FALSE(error());
    }
  }
  EXPECT_TRUE(empty());
}

TEST_F(FifoTest, FlagsEmptyFullEmpty) {
  EXPECT_TRUE(empty());
  EXPECT_TRUE(almostEmpty());
  push(1);
  EXPECT_FALSE(empty());
  EXPECT_TRUE(almostEmpty());
  for (uint32_t i = 2; i < 8; i++) {
    push(i);
    EXPECT_FALSE(almostEmpty());
    EXPECT_FALSE(halfFull());
  }
  push(8);
  EXPECT_TRUE(halfFull());
  EXPECT_FALSE(almostFull());
  for (uint32_t i = 9; i < 15; i++) {
    push(i);
    EXPECT_FALSE(almostFull());
  }
  push(15);
  EXPECT_TRUE(almostFull());
  EXPECT_FALSE(full());
  push(16);
  EXPECT_TRUE(full());
  EXPECT_EQ(pop(), 1);
  EXPECT_FALSE(full());
  EXPECT_TRUE(almostFull());
  EXPECT_EQ(pop(), 2);
  EXPECT_FALSE(almostFull());
  EXPECT_TRUE(halfFull());
  for (uint32_t i = 3; i < 9; i++) {
    EXPECT_EQ(pop(), i);
    EXPECT_TRUE(halfFull());
  }
  EXPECT_EQ(pop(), 9);
  EXPECT_FALSE(halfFull());
  EXPECT_FALSE(almostEmpty());
  for (uint32_t i = 10; i < 15; i++) {
    EXPECT_EQ(pop(), i);
    EXPECT_FALSE(almostEmpty());
  }
  EXPECT_EQ(pop(), 15);
  EXPECT_TRUE(almostEmpty());
  EXPECT_FALSE(empty());
  EXPECT_EQ(pop(), 16);
  EXPECT_TRUE(empty());
}

TEST_F(FifoTest, PushPopRandom) {
  FifoModel model;

  // Random number generator
  std::mt19937 gen(/*seed*/0);
  std::uniform_int_distribution<uint32_t> val_d; // For values to push/pop
  std::bernoulli_distribution act_d(0.5); // For actions to perform

  for (int i = 0; i < 10000; i++) {
    auto a = act_d(gen);
    if (model.empty()) {
      model.push(i);
      push(i);
    } else if (model.full()) {
      EXPECT_EQ(pop(), model.pop());
    } else {
      if (a == 0) {
        model.push(i);
        push(i);
      } else {
        EXPECT_EQ(pop(), model.pop());
      }
    }
    EXPECT_EQ(flags(), model.flags());
  }
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
