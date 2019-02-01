#include <cstdint>
#include <memory>

#include "Eigen/Dense"

#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "gcn/test/verilator_driver.h"
#include "gcn/test/Vexecute/Vexecute.h"

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <iterator>

using Matrix = Eigen::Matrix<uint16_t, Eigen::Dynamic, Eigen::Dynamic>;
//using MapMatrix = Map<Matrix>;

#define _MAX_FEAT_VAL   10
#define _BATCH_SIZE     128

// Per Node Defines
#define _NUM_FEAT       256 // We define hidden layer to be same as I/O num features
#define _NUM_NEIGHBORS  8

// Test fixture:
// https://github.com/google/googletest/blob/master/googletest/docs/primer.md#test-fixtures-using-the-same-data-configuration-for-multiple-tests

// List of assertions in GTest:
// https://github.com/google/googletest/blob/master/googletest/docs/primer.md#basic-assertions

class ExecuteTest : public ::testing::Test {
  protected:
      VerilatorDUT<Vexecute> dut;
      void reset()
      {
          dut.poke(&Vexecute::clock, 0);
          dut.poke(&Vexecute::reset_n, 0);
          dut.step(21);
          dut.poke(&Vexecute::reset_n, 1);
      }

      /*
      uint16_t process()
      {   // Should assert out_valid is low before each valid data comes in, or some handling
          dut.pokeArray(&Vexecute::in_data, I);
          dut.pokeArray(&Vexecute::in_weight, W);
          dut.pokeArray(&Vexecute::in_activate, A);
          dut.poke(&Vexecute::in_valid, 1);

          while (!dut.peek(&Vexecute::out_valid))
              dut.step(10); // Add cycle counter here for perf

          O_sim = dut.peekArray(&Vexecute::out_data);
          return 0;
      }
      */

  /*---------------------------------------------------------------------------------------------------------
   * Notes:
   *
   * INPUT = (_NUM_FEAT*2, _BATCH_SIZE); // Embedding/features for current node
   *    sum(NGHBORs)+INPUT (each _NUM_FEATx_BATCH_SIZE) are concatenated into (_NUM_FEAT*2 x _BATCH_SIZE) matrix.
   *
   * WEIGHT = (_NUM_FEAT*2 _NUM_FEAT); // Set of neighbor weights (same for all neighbors)
   *    1st convolve: M = I_t * W = (_NUM_FEAT*2 x _BATCH_SIZE) ^ T * (_NUM_FEAT*2 x _NUM_FEAT) = (_BATCH_SIZE x _NUM_FEAT)
   *
   * ACTIVATE = (_NUM_FEAT, _NUM_FEAT); // Set of activations
   *    2nd convolve: O = M * A = (_BATCH_SIZE x _NUM_FEAT) * (_NUM_FEAT x _NUM_FEAT) = (_BATCH_SIZE x _NUM_FEAT)
   *---------------------------------------------------------------------------------------------------------*/

  /*
  // std array
  std::array<std::array<uint16_t, _NUM_FEAT*2>, _BATCH_SIZE> I;
  std::array<std::array<uint16_t, _NUM_FEAT*2>, _NUM_FEAT>   W;
  std::array<std::array<uint16_t, _NUM_FEAT>,   _NUM_FEAT>   A;
  std::array<std::array<uint16_t, _BATCH_SIZE>, _NUM_FEAT>   M_gold;
  std::array<std::array<uint16_t, _BATCH_SIZE>, _NUM_FEAT>   O_gold;
  */

  // c array
  std::array<uint16_t[_BATCH_SIZE], _NUM_FEAT*2> I;
  std::array<uint16_t[_NUM_FEAT],   _NUM_FEAT*2> W;
  std::array<uint16_t[_NUM_FEAT],   _NUM_FEAT>   A;

  std::array<uint16_t[_NUM_FEAT], _BATCH_SIZE>   M_gold;
  std::array<uint16_t[_NUM_FEAT], _BATCH_SIZE>   O_gold;
  std::array<uint16_t[_NUM_FEAT], _BATCH_SIZE>   O_sim;

  /* Reversed dimensions
  std::array<uint16_t[_NUM_FEAT*2], _BATCH_SIZE> I;
  std::array<uint16_t[_NUM_FEAT*2], _NUM_FEAT  > W;
  std::array<uint16_t[_NUM_FEAT],   _NUM_FEAT>   A;

  std::array<uint16_t[_BATCH_SIZE], _NUM_FEAT>   M_gold;
  std::array<uint16_t[_BATCH_SIZE], _NUM_FEAT>   O_gold;
  std::array<uint16_t[_BATCH_SIZE], _NUM_FEAT>   O_sim;
  */

  // Workaround: Populate matrices for gold computation
  Matrix m_I = {_NUM_FEAT*2, _BATCH_SIZE};
  Matrix m_W = {_NUM_FEAT*2, _NUM_FEAT};
  Matrix m_A = {_NUM_FEAT, _NUM_FEAT};

  Matrix m_M_gold = {_BATCH_SIZE, _NUM_FEAT};
  Matrix m_O_gold = {_BATCH_SIZE, _NUM_FEAT};
  Matrix m_O_sim  = {_BATCH_SIZE, _NUM_FEAT};

};

// This should read in test vectors to matrixes, run simulation/gold computation, and assert equal results.
TEST_F(ExecuteTest, Test) {
  // 1. Populate matrices from test vectors
  std::string line;
  std::string infile_ptr = "gcn/test/testvectors/data.txt";
  std::ifstream infile(infile_ptr);
  if (infile.is_open())
  {
    std::cout << "Populating matrices from " << infile_ptr << std::endl;
    int input_counter = _NUM_FEAT*2;
    int weight_counter = _NUM_FEAT*2;

    int input_idx = 0;
    int weight_idx = 0;
    int activate_idx = 0;

    while ( std::getline (infile,line) )
    {
        // Convert each line into vector of uint16_t
        std::stringstream iss( line );
        uint16_t number;
        std::vector<uint16_t> myNumbers;
        while ( iss >> number )
            myNumbers.push_back( number );

        // Assign vector to corresponding row in the correct 2D array/Matrix
        if (input_counter > 0)
        {
            for (int i = 0; i < myNumbers.size(); i++)
            {
                I[input_idx][i] = myNumbers[i];
                m_I(input_idx, i) = myNumbers[i];
            }
            input_counter--;
            input_idx++;
        }
        else if (weight_counter > 0)
        {
            for (int i = 0; i < myNumbers.size(); i++)
            {
                W[weight_idx][i] = myNumbers[i];
                m_W(weight_idx, i) = myNumbers[i];
            }
            weight_counter--;
            weight_idx++;
        }
        else
        {
            for (int i = 0; i < myNumbers.size(); i++)
            {
                A[activate_idx][i] = myNumbers[i];
                m_A(activate_idx, i) = myNumbers[i];
            }
            activate_idx++;
        }
    }
    infile.close();
    ASSERT_EQ(input_idx, _NUM_FEAT*2);
    ASSERT_EQ(weight_idx, _NUM_FEAT*2);
    ASSERT_EQ(activate_idx, _NUM_FEAT);
  }
  else std::cout << "Unable to open input file";

  // 2a. Compute gold results
  m_M_gold = (m_I.transpose() * m_W);
  m_O_gold = (m_M_gold * m_A);
  for (int i = 0; i < _BATCH_SIZE ; i++)
    for (int j = 0; j < _NUM_FEAT ; j++)
        O_gold[i][j] = m_O_gold(i, j);

  // 2b. Run simulation
  //process(I, W, A); // uncomment after logic completion

  // 3. Assert equal results
  //ASSERT_EQ(O_gold, O_sim); // uncomment after logic completion

}


TEST_F(ExecuteTest, forceFailToPrintResults) {
  ASSERT_EQ(0, 1);
}


int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  // Global verilator setup
  // Verilated::commandArgs(argc, argv);
  // Verilated::traceEverOn(false);
  // Verilated::debug(0);
  // Verilated::randReset(0);

  return RUN_ALL_TESTS();
}
