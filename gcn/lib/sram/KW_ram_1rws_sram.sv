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
  input logic cs_n,
  input logic we_n,
  input logic re_n,

  /* Port 1 datapath */
  input  logic [ADDR_WIDTH-1:0] rw_addr,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
);
  // Helper macro
`define SRAM(n,w) \
  SRAM1RW``n``x``w sram_``n``x``w ( \
    .A  (rw_addr),  \
    .CE (clock),    \
    .WEB(we_n),     \
    .OEB(re_n),     \
    .CSB(cs_n),     \
    .I  (data_in),  \
    .O  (data_out)  \
  );

`define if_SRAM(n,w) \
  if (DEPTH == (n) && DATA_WIDTH == (w)) begin `SRAM(n,w) end

  // Instance the SRAMs
  generate
    `if_SRAM( 128,  8)
    else `if_SRAM(  64, 32)
    else `if_SRAM( 256, 32)
    else `if_SRAM(1024,  8) // Datasheet says 102x84, but 1024x8 is the correct cell name
    else `if_SRAM( 512,  8)
    else `if_SRAM( 128, 48)
    else `if_SRAM(  32, 50)
    else `if_SRAM( 256, 46)
    else `if_SRAM( 128, 46)
    else `if_SRAM(  64,  8)
    else `if_SRAM(  64,128)
    else `if_SRAM( 256,128)
    else `if_SRAM( 256,  8)
    else `if_SRAM( 256, 48)
    else `if_SRAM( 512,128)
    else `if_SRAM( 512, 32)
    else INVALID_INSTANCE requested_sram_module_not_defined();
  endgenerate
`undef if_SRAM
`undef SRAM
endmodule
