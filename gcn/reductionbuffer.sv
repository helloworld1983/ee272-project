`default_nettype none

module reductionbuffer (
  input logic clock,
  input logic reset_n,

  /* Control interface */
  // NOTE: A swap occurs on the positive edge of clock after ready/valid
  // are both 1
  output logic swap_ready, // The accumulator buffer is ready to swap
  input  logic swap_valid, // The accumulator buffer has a request to swap

  // Write interface
  input logic              w_en_n, // Enable writing to the activation buffer. Active low.
  input logic [ 7:0]       w_addr, // Write address
  input logic [15:0][15:0] w_data, // Data input from the MAC array

  // Read interface
  input  logic              r_en_n, // Read from the activation buffer. Active low.
  input  logic [ 7:0]       r_addr, // Read address
  output logic [15:0][15:0] r_data  // The resulting activations
);
  // Toggle the swap index when requested
  logic [0:0] r_bank;
  logic [0:0] w_bank;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      r_bank <= 1'b0;
      w_bank <= 1'b1;
    end else if (swap_ready && swap_valid) begin
      r_bank <= w_bank;
      w_bank <= r_bank;
    end
  end
  assign swap_ready = 1'b1;

  // SRAM banks
  localparam int SRAM_WIDTH = 128;
  localparam int SRAM_DEPTH = 256;
  localparam int SRAM_TILES = 256 / SRAM_WIDTH;
  localparam int SRAM_ADDRW = $clog2(SRAM_DEPTH);
  genvar i, j;
  generate
    for (i = 0; i < 2; i = i + 1) begin : BANK
      wire bank_r_en_n = (r_bank == i) ? r_en_n : 1'b1;
      wire bank_w_en_n = (w_bank == i) ? w_en_n : 1'b1;
      wire [SRAM_ADDRW-1:0] bank_addr = !bank_r_en_n ? r_addr : w_addr;
      wire [SRAM_TILES-1:0][SRAM_WIDTH-1:0] bank_data_in = w_data;
      wire [SRAM_TILES-1:0][SRAM_WIDTH-1:0] bank_data_out;

      for (j = 0; j < SRAM_TILES; j = j + 1) begin : SRAM
        KW_ram_1rws_sram #(
          .DATA_WIDTH(SRAM_WIDTH),
          .DEPTH     (SRAM_DEPTH)
        ) mem (
          .clock   (clock),
          .reset_n (reset_n),
          .cs_n    (1'b0),
          .we_n    (bank_w_en_n),
          .re_n    (bank_r_en_n),
          .rw_addr (bank_addr),
          .data_in (bank_data_in [j]),
          .data_out(bank_data_out[j])
        );
      end : SRAM
    end : BANK
  endgenerate

  assign r_data = (r_bank == 0 ? BANK[0].bank_data_out : BANK[1].bank_data_out);
endmodule
