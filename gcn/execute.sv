`default_nettype none

// Wrapper around GCN execution back-end
module execute (
  input logic clock,
  input logic reset_n,

  output logic swap_ready,
  input  logic swap_valid,

  /* Read channel */
  input  logic              r_en_n,
  input  logic [ 7:0]       r_addr,
  output logic [15:0][15:0] r_data
);
  logic              w_en_n;
  logic [ 7:0]       w_addr;
  logic [15:0][15:0] w_data;

  reductionbuffer rbuf (
    .clock(clock),
    .reset_n(reset_n),

    .swap_ready(swap_ready),
    .swap_valid(swap_valid),

    /* Write channel */
    .w_en_n(w_en_n),
    .w_addr(w_addr),
    .w_data(w_data),

    /* Read channel */
    .r_en_n(r_en_n),
    .r_addr(r_addr),
    .r_data(r_data)
  );
endmodule
