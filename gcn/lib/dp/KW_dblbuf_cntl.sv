`default_nettype none

// Controller for a double buffer.
module KW_dblbuf_cntl #(
  parameter int DATA_WIDTH, // Data width
  parameter int ADDR_WIDTH  // Address width
) (
  input logic clock,
  input logic reset_n,

  /* Swap controller */
  input logic swap_n, // Swap buffers on positive edge of clock. Active low

  /* Input write port */
  input logic w_en_n, // Write enable. Active low.
  input logic [ADDR_WIDTH-1:0] w_addr, // Write address
  input logic [DATA_WIDTH-1:0] w_data, // Write data

  /* Input read port */
  input  logic r_en_n, // Read enable. Active low.
  input  logic [ADDR_WIDTH-1:0] r_addr, // Read address
  output logic [DATA_WIDTH-1:0] r_data, // Read data

  /* Ouput rw port 1 */
  output logic rw1_cs_n, // Chip select. Active low.
  output logic rw1_we_n, // Write enable. Active low.
  output logic rw1_re_n, // Read enable. Active low.
  output logic [ADDR_WIDTH-1:0] rw1_addr,
  output logic [DATA_WIDTH-1:0] rw1_data_in,
  input  logic [DATA_WIDTH-1:0] rw1_data_out,

  /* Output rw port 2 */
  output logic rw2_cs_n, // Chip select. Active low.
  output logic rw2_we_n, // Write enable. Active low.
  output logic rw2_re_n, // Read enable. Active low.
  output logic [ADDR_WIDTH-1:0] rw2_addr,     // RAM r/w address
  output logic [DATA_WIDTH-1:0] rw2_data_in,  // RAM data input
  input  logic [DATA_WIDTH-1:0] rw2_data_out  // RAM data output
);
  logic r_bank;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      r_bank <= 1'b0;
    end else if (~swap_n) begin
      r_bank <= !r_bank;
    end
  end

  assign rw1_cs_n = (r_bank == 0) ? r_en_n : w_en_n;
  assign rw1_we_n = (r_bank == 0); // we_n is 1 if NOT writing
  assign rw1_addr = (r_bank == 0) ? r_addr : w_addr;

  assign rw2_cs_n = (r_bank == 1) ? r_en_n : w_en_n;
  assign rw2_we_n = (r_bank == 1); // we_n is 1 if NOT writing
  assign rw2_addr = (r_bank == 1) ? r_addr : w_addr;

  assign rw1_data_in = (r_bank == 0) ? {DATA_WIDTH{1'bX}} : w_data;
  assign rw2_data_in = (r_bank == 1) ? {DATA_WIDTH{1'bX}} : w_data;
  assign r_data = (r_bank == 0) ? rw1_data_out : rw2_data_out;
endmodule
