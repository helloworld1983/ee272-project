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

  /*
  Matrix INPUT(_NUM_FEAT*2, _BATCH_SIZE); // Embedding/features for current node
  // sum(NGHBORs)+INPUT (each _NUM_FEATx_BATCH_SIZE) are concatenated into (_NUM_FEAT*2 x _BATCH_SIZE) matrix.

  Matrix WGHTS(_NUM_FEAT*2 _NUM_FEAT); // Set of neighbor weights (same for all neighbors)
  // 1st convolve: M = I_t * W = (_NUM_FEAT*2 x _BATCH_SIZE) ^ T * (_NUM_FEAT*2 x _NUM_FEAT) = (_BATCH_SIZE x _NUM_FEAT)

  Matrix ACTIV(_NUM_FEAT, _NUM_FEAT); // Set of activations
  // 2nd convolve: O = M * A = (_BATCH_SIZE x _NUM_FEAT) * (_NUM_FEAT x _NUM_FEAT) = (_BATCH_SIZE x _NUM_FEAT)
  */
  Matrix I = {_NUM_FEAT*2, _BATCH_SIZE};
  Matrix W = {_NUM_FEAT*2, _NUM_FEAT};
  Matrix A = {_NUM_FEAT, _NUM_FEAT};

  Matrix M = {_BATCH_SIZE, _NUM_FEAT};
  Matrix O = {_BATCH_SIZE, _NUM_FEAT};

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

        // Assign vector to corresponding row in the correct Matrix
        if (input_counter > 0)
        {
            for (int i = 0; i < myNumbers.size(); i++)
                I(input_idx, i) = myNumbers[i];
            input_counter--;
            input_idx++;
        }
        else if (weight_counter > 0)
        {
            for (int i = 0; i < myNumbers.size(); i++)
                W(weight_idx, i) = myNumbers[i];
            weight_counter--;
            weight_idx++;
        }
        else
        {
            for (int i = 0; i < myNumbers.size(); i++)
                A(activate_idx, i) = myNumbers[i];
            activate_idx++;
        }
    }
    infile.close();
    ASSERT_EQ(input_idx, _NUM_FEAT*2);
    ASSERT_EQ(weight_idx, _NUM_FEAT*2);
    ASSERT_EQ(activate_idx, _NUM_FEAT);
  }
  else std::cout << "Unable to open input file";

  std::cout << W << std::endl;

  // 2a. Compute gold results
  M = (I.transpose() * W);
  O = (M * A);

  // 2b. Run simulation (TODO)
  /*
  for (int i = 0; i < _NUM_FEAT*2; i++)
    for (int j = 0; j < _BATCH_SIZE; j++)
      //I(i,j) = atoi(input_tokens[i*_BATCH_SIZE + j]); // Cast to INT (FIXME may need casting update)
      std::cout << input_tokens[i*_BATCH_SIZE + j] << std::endl;
      //uint16_t myint = static_cast<uint16_t>(input_tokens[i*_BATCH_SIZE + j]);

  for (int i = 0; i < _NUM_FEAT*2; i++)
    for (int j = 0; j < _NUM_FEAT; j++)
      W(i,j) = int(weight_tokens[i*_NUM_FEAT + j]);

  for (int i = 0; i < _NUM_FEAT; i++)
    for (int j = 0; j < _NUM_FEAT; j++)
      A(i,j) = int(activate_tokens[i*_NUM_FEAT + j]);
  */

  // 3. Assert equal results (TODO)


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
