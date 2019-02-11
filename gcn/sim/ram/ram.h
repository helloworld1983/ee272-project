#ifndef RAM_H
#define RAM_H

#include <cstdint>
#include <cassert>
#include <istream>

#include "absl/container/flat_hash_map.h"

class Ram {
  // Since the memory is potentially large, we use a sparse hash map
  absl::flat_hash_map<uint32_t, uint32_t> memory_;

public:
  Ram(uint32_t addr_width, uint32_t data_width) noexcept
  {
    assert(addr_width >= 1 && addr_width <= 32 && "Address size must be between 1-32 bits");
    assert(data_width == 32 && "Data width must be 32 bits");
  }

  auto size() const noexcept { return memory_.size(); }

  void reset() { memory_.clear(); }
  void write(uint32_t address, uint32_t data) { memory_[address] = data; }
  void read(uint32_t address, uint32_t* data) { *data = memory_[address]; }

  int readmemh(const char* filename, uint32_t start = 0);
  int readmemh(std::istream& is, uint32_t start = 0);
};

#endif
