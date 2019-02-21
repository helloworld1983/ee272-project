`default_nettype none

// Dual Synchronous Read/Write-Port SRAM
// Note: Uses a simulation model for verilator
module KW_ram_1rws_sram #(
  parameter int DATA_WIDTH, // Width of data_in and data_out buses.
  parameter int DEPTH,      // Number of words in the memory array.

  // Number of address bits. Do not override.
  parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
  input logic clock,
  input logic reset_n,

  /* Port 1 control */
  input logic p1_cs_n,
  input logic p1_we_n,
  input logic p1_re_n,

  /* Port 1 datapath */
  input  logic [ADDR_WIDTH-1:0] p1_addr,
  input  logic [DATA_WIDTH-1:0] p1_data_in,
  output logic [DATA_WIDTH-1:0] p1_data_out
);
  // Helper macro
`define SRAM(n,w) \
  SRAM1RW``n``x``w sram_``n``x``w ( \
    .A1  (p1_addr),     \
    .CE1 (clock),       \
    .WEB1(p1_we_n),     \
    .OEB1(p1_re_n),     \
    .I   (p1_data_in),  \
    .O   (p1_data_out), \
    .A   (p2_addr),     \
  );

`define if_SRAM(n,w) \
  if (DEPTH == (n) && DATA_WIDTH == (w)) begin `SRAM(n,w) end

  // Instance the SRAMs
  generate
    `if_SRAM(128,  8)
    else `if_SRAM( 64, 32)
    else `if_SRAM(256, 32)
    else `if_SRAM(102, 84)
    else `if_SRAM(512,  8)
    else `if_SRAM(128, 48)
    else `if_SRAM( 32, 50)
    else `if_SRAM(256, 46)
    else `if_SRAM(128, 46)
    else `if_SRAM( 64,  8)
    else `if_SRAM( 64,128)
    else `if_SRAM(256,128)
    else `if_SRAM(256,  8)
    else `if_SRAM(256, 48)
    else `if_SRAM(512,128)
    else `if_SRAM(512, 32)
    else INVALID_INSTANCE requested_sram_module_not_defined();
  endgenerate
`undef if_SRAM
`undef SRAM
endmodule
