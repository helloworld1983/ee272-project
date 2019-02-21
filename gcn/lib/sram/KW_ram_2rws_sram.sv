`default_nettype none

// Dual Synchronous Read/Write-Port SRAM
// Note: Uses a simulation model for verilator
module KW_ram_2rws_sram #(
  parameter int DATA_WIDTH, // Width of data_in and data_out buses. Must be between 1-256
  parameter int DEPTH,      // Number of words in the memory array. Must be between 2-256

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
  output logic [DATA_WIDTH-1:0] p1_data_out,

  /* Port 2 control */
  input logic p1_cs_n,
  input logic p1_we_n,
  input logic p1_re_n,

  /* Port 2 datapath */
  input  logic [ADDR_WIDTH-1:0] p2_addr,
  input  logic [DATA_WIDTH-1:0] p2_data_in,
  output logic [DATA_WIDTH-1:0] p2_data_out
);
  // Helper macro
`define SRAM(n,w) \
  SRAM2RW``n``x``w sram_``n``x``w ( \
    .A1  (p1_addr),     \
    .CE1 (clock),       \
    .WEB1(p1_we_n),     \
    .OEB1(p1_re_n),     \
    .I1  (p1_data_in),  \
    .O1  (p1_data_out), \
    .A2  (p2_addr),     \
    .CE2 (clock),       \
    .WEB2(p2_we_n),     \
    .OEB2(p2_oe_n),     \
    .I2  (p2_data_in),  \
    .O2  (p2_data_out)  \
  );

`define if_SRAM(n,w) \
  if (DEPTH == (n) && DATA_WIDTH == (w)) begin `SRAM(n,w) end

  // Instance the SRAMs
  generate
    `if_SRAM( 16, 4)
    else `if_SRAM( 32, 4)
    else `if_SRAM( 64, 4)
    else `if_SRAM(128, 4)
    else `if_SRAM( 16, 8)
    else `if_SRAM( 32, 8)
    else `if_SRAM( 64, 8)
    else `if_SRAM(128, 8)
    else `if_SRAM( 16,16)
    else `if_SRAM( 32,16)
    else `if_SRAM( 64,16)
    else `if_SRAM(128,16)
    else `if_SRAM( 16,32)
    else `if_SRAM( 32,32)
    else `if_SRAM( 64,32)
    else `if_SRAM(128,32)
    else `if_SRAM( 32,22)
    else `if_SRAM( 32,39)
    else INVALID_INSTANCE requested_sram_module_not_defined();
  endgenerate
`undef if_SRAM
`undef SRAM
endmodule
