#include <iostream>
#include <memory>
#include <utility>

#include "{{Vtop}}/{{Vtop}}.h"

#include "verilated.h"
#if VM_TRACE
#include "verilated_vcd_c.h"
#endif

// Current simulation time
// This is a 64-bit integer to reduce wrap over issues
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() { return main_time; }

// Number of cycles before timeout
// TODO - make configurable
static const vluint64_t timeout = 100000UL;

int main(int argc, char** argv, char** env) {
  Verilated::commandArgs(argc, argv);
  Verilated::debug(0);
  Verilated::randReset(2);

  // Init top verilog instance
  auto top = std::make_unique<{{Vtop}}>();

#if VM_TRACE
  const char *dir = std::getenv("TEST_UNDECLARED_OUTPUTS_DIR");
  std::string path = std::string(dir ? dir : ".") + "/dump.vcd";
  Verilated::traceEverOn(true);  // Verilator must compute traced signals
  auto tfp = std::make_unique<VerilatedVcdC>();
  top->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
  tfp->open(path.c_str());
#endif

  top->reset = 1;
  while (!Verilated::gotFinish() && main_time < timeout) {
    if (main_time > 20) {
      top->reset = 0;  // Deassert reset
    }
    if ((main_time % 10) == 1) {
      top->clock = 1;  // Toggle clock
    }
    if ((main_time % 10) == 6) {
      top->clock = 0;  // Toggle clock
    }
    top->eval();  // Evaluate model

#if VM_TRACE
    if (tfp) tfp->dump(main_time);  // Create waveform trace for this timestamp
#endif

    main_time++;  // Time passes...
  }

  if (main_time >= timeout) {
    std::cerr << "Simulation terminated by timeout at time " << main_time;
    std::cerr << " (cycle " << main_time / 10 << ")";
    std::cerr << std::endl;
    return -1;
  } else {
    std::cerr << "Simulation completed at time " << main_time;
    std::cerr << " (cycle " << main_time / 10 << ")";
    std::cerr << std::endl;
  }

#if 0
  // Run for 10 more clocks
  const vluint64_t end_time = main_time + 100;
  while (main_time < end_time) {
    if ((main_time % 10) == 1) {
      top->clock = 1;  // Toggle clock
    }
    if ((main_time % 10) == 6) {
      top->clock = 0;  // Toggle clock
    }
    top->eval();  // Evaluate model

#if VM_TRACE
    if (tfp) tfp->dump(main_time);  // Create waveform trace for this timestamp
#endif

    main_time++;  // Time passes...
  }
#endif

  // Run final blocks
  top->final();

#if VM_TRACE
  if (tfp) tfp->close();
#endif
}
