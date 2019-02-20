`default_nettype none

// Synchronous Write-Port, Asynchronous Read-Port RAM (Flip-Flop-Based)
module KW_ram_1ra_1ws_dff #(
  parameter int DATA_WIDTH, // Width of data_in and data_out buses. Must be between 1-256
  parameter int DEPTH,      // Number of words in the memory array. Must be between 2-256

  // Determines if the reset_n input is used
  // 0: reset_n initializes the SRAM
  // 1: reset_n is not connected
  parameter bit RESET_MODE = 1,

  // Number of address bits. Do not override.
  parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
  input wire clock,   // Clock
  input wire reset_n, // Reset, active low, ASYNC

  input wire cs_n, // Chip select, active low
  input wire we_n, // Write enable, active low

  /* Datapath */
  input  wire [ADDR_WIDTH-1:0] wr_addr,
  input  wire [ADDR_WIDTH-1:0] rd_addr,

  input  wire [DATA_WIDTH-1:0] data_in,
  output reg  [DATA_WIDTH-1:0] data_out
);
  initial begin
    assert (DATA_WIDTH >= 1 && DATA_WIDTH <= 256) else
      $fatal("Invalid DATA_WIDTH");
    assert (DEPTH >= 2 && DEPTH <= 256) else
      $fatal("Invalid DEPTH");
    assert (RESET_MODE == 0 || RESET_MODE == 1) else
      $fatal("Invalid RESET_MODE");
  end

  reg [DEPTH-1:0][DATA_WIDTH-1:0] memory;

  // Synchronous write
  generate
    if (RESET_MODE == 0) begin
      always_ff @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
          memory <= {DEPTH * DATA_WIDTH{1'b0}};
        end else if (~ce_n && ~we_n) begin
          memory[wr_addr] <= data_in;
        end
      end
    end else begin
      always_ff @(posedge clock) begin
        if (~ce_n && ~we_n) begin
          memory[wr_addr] <= data_in;
        end
      end
    end
  endgenerate

  // Asynchronous read
  assign data_out = memory[rd_addr];
endmodule
