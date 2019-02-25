`default_nettype none

// Wrapper around GCN execution back-end
module execute (
  input logic clock,
  input logic reset_n,

  /* Swap control */
  output logic swap_ready,
  input  logic swap_valid,

  /* Mac write channel */
  input logic mac_w_en_n,
  input logic [3:0] mac_w_col,
  input logic [4:0] mac_w_addr,
  input logic [3:0][3:0][15:0] mac_w_data,

  /* Mac input channel */
  input logic mac_r_en_n,
  input logic [4:0] mac_r_addr,
  input logic [3:0][3:0][15:0] mac_a,
  input logic [3:0][3:0][15:0] mac_c,

  /* RBuf Read channel */
  input  logic              rbuf_r_en_n,
  input  logic [ 7:0]       rbuf_r_addr,
  output logic [15:0][15:0] rbuf_r_data
);
  logic rbuf_swap_ready, rbuf_swap_valid;
  logic rbuf_w_en_n;
  logic [7:0] rbuf_w_addr;
  logic [15:0][15:0] rbuf_w_data;

  // Swapping logic
  assign swap_ready = rbuf_swap_ready;
  wire mac_swap_n = swap_valid;

  mac16x16 mac (
    .clock  (clock),
    .reset_n(reset_n),

    .swap_n (mac_swap_n),

    .w_en_n (mac_w_en_n),
    .w_col  (mac_w_col),
    .w_addr (mac_w_addr),
    .w_data (mac_w_data),

    .r_en_n (mac_r_en_n),
    .r_addr (mac_r_addr),

    .a      (mac_a),
    .c      (mac_c),
    .x      (rbuf_w_data)
  );

  // Delay the other signals to match the delay through the MAC
  logic rbuf_w_en_n_ff;
  logic [7:0] rbuf_w_addr_ff;
  KW_pipe_reg #(
    .DATA_WIDTH(9),
    .DEPTH(2)
  ) pipe (
    .clock  (clock),
    .reset_n(reset_n),
    .a      ({rbuf_w_en_n, rbuf_w_addr}),
    .b      ({rbuf_w_en_n_ff, rbuf_w_addr_ff})
  );

  reductionbuffer rbuf (
    .clock(clock),
    .reset_n(reset_n),

    /* Swap channel */
    .swap_ready(rbuf_swap_ready),
    .swap_valid(rbuf_swap_valid),

    /* Write channel */
    .w_en_n(rbuf_w_en_n_ff),
    .w_addr(rbuf_w_addr_ff),
    .w_data(rbuf_w_data),

    /* Read channel */
    .r_en_n(rbuf_r_en_n),
    .r_addr(rbuf_r_addr),
    .r_data(rbuf_r_data)
  );
endmodule
