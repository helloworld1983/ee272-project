#include <cstdint>
#include <fstream>
#include <istream>
#include <sstream>
#include <string>
#include <stdexcept>

#include "gcn/sim/ram/ram.h"

int Ram::readmemh(const char* filename, uint32_t start) {
  std::ifstream is(filename);
  if (is.fail()) {
    return -1;
  }
  return readmemh(is, start);
}

int Ram::readmemh(std::istream& is, uint32_t start) {
  uint32_t addr = start;
  std::string line;
  while (std::getline(is, line)) {
    // Remove any comments if they exist
    line = line.substr(0, line.find("//"));
    // Check for bad charcters
    if (line.find_first_not_of("0123456789abcdefABCDEF@ \t\r\n") != std::string::npos) {
      return -1;
    }
    std::stringstream ss(line);
    std::string word;
    try {
      while (ss >> word) {
        if (!word.empty() && word[0] == '@') {
          addr = std::stol(word.substr(1), nullptr, 16);
          continue;
        }
        write(addr++, std::stol(word, nullptr, 16));
      }
    } catch (std::logic_error& e) {
      // If the string was parsed incorrectly
      return -1;
    }
  }
  return is.bad() ? -1 : 0;
}
