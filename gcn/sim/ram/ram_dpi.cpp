#include <cstdint>
#include <string>

#include "absl/container/flat_hash_map.h"

#include "svdpi.h"

#include "gcn/sim/ram/ram.h"

absl::flat_hash_map<std::string, Ram*> g_ram_registry;

// Convience method to help convert to a Ram*
static auto cast(void* handle) { return static_cast<Ram*>(handle); }

extern "C" void* ram_alloc(uint32_t addr_width, uint32_t data_width) {
  // The name is unique for each scope, so we can use it without conflict
  auto name = svGetNameFromScope(svGetScope());
  auto ram = new Ram(addr_width, data_width);
  g_ram_registry[name] = ram;
  return ram;
}

extern "C" void ram_readmemh(void* handle, const char* filename) {
  cast(handle)->readmemh(filename);
}

extern "C" void ram_reset(void* handle) {
  cast(handle)->reset();
}

extern "C" void ram_write(void* handle, uint32_t address, uint32_t data) {
  cast(handle)->write(address, data);
}

extern "C" void ram_read(void* handle, uint32_t address, uint32_t* data) {
  cast(handle)->read(address, data);
}
