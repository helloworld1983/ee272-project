`default_nettype none

// Single Synchronous Read/Write-Port RAM (Flip-Flop Based)
module KW_ram_1rws_dff #(
  parameter int DATA_WIDTH, // Width of data_in and data_out buses.
  parameter int DEPTH,      // Number of words in the memory array.

  // Determines if the reset_n input is used
  // 0: reset_n initializes the SRAM
  // 1: reset_n is not connected
  parameter bit RESET_MODE = 1,

  // Number of address bits. Do not override.
  parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
  input logic clock,
  input logic reset_n,

  /* Port 1 control */
  input logic cs_n,
  input logic we_n,

  /* Port 1 datapath */
  input  logic [ADDR_WIDTH-1:0] rw_addr,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
);
  logic [DEPTH-1:0][DATA_WIDTH-1:0] memory;
  wire re = ~cs_n &&  we_n;
  wire we = ~cs_n && ~we_n;

  generate
    if (RESET_MODE == 0) begin
      always_ff @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
          memory   <= {DEPTH * DATA_WIDTH{1'b0}};
          data_out <= {DATA_WIDTH{1'b0}};
        end else begin
          if (we) begin
            memory[rw_addr] <= data_in;
          end
          if (re) begin
            data_out <= memory[rw_addr];
          end
        end
      end
    end else begin
      always_ff @(posedge clock) begin
        if (we) begin
          memory[rw_addr] <= data_in;
        end
        if (re) begin
          data_out <= memory[rw_addr];
        end
      end
    end
  endgenerate
endmodule
