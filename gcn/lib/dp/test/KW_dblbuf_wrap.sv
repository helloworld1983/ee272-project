`default_nettype none

`define DATA_WIDTH (16)
`define DEPTH      (32)
`define ADDR_WIDTH ($clog2(`DEPTH))

module KW_dblbuf_wrap (
  input logic clock,
  input logic reset_n,

  input logic swap_n,

  input logic w_en_n,
  input logic [`ADDR_WIDTH-1:0] w_addr,
  input logic [`DATA_WIDTH-1:0] w_data,

  input  logic r_en_n,
  input  logic [`ADDR_WIDTH-1:0] r_addr,
  output logic [`DATA_WIDTH-1:0] r_data
);
  KW_dblbuf #(
    .DATA_WIDTH(`DATA_WIDTH),
    .DEPTH(`DEPTH)
  ) dut (
    .clock(clock),
    .reset_n(reset_n),
    .swap_n(swap_n),
    .w_en_n(w_en_n),
    .w_addr(w_addr),
    .w_data(w_data),
    .r_en_n(r_en_n),
    .r_addr(r_addr),
    .r_data(r_data)
  );
endmodule
