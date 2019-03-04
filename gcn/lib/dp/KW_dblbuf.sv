`default_nettype none

module KW_dblbuf #(
  parameter int DATA_WIDTH, // Data width
  parameter int DEPTH,      // Double buffer depth

  parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
  input logic clock,
  input logic reset_n,

  /* Swap controller */
  input logic swap_n,

  /* Input write port */
  input logic w_en_n, // Write enable. Active low.
  input logic [ADDR_WIDTH-1:0] w_addr, // Write address
  input logic [DATA_WIDTH-1:0] w_data, // Write data

  /* Input read port */
  input  logic r_en_n, // Read enable. Active low.
  input  logic [ADDR_WIDTH-1:0] r_addr, // Read address
  output logic [DATA_WIDTH-1:0] r_data  // Read data
);
`ifndef SYNTHESIS
  initial begin
    assert (DATA_WIDTH >= 1) else
      $fatal("DATA_WIDTH must be >= 1");
    assert (DEPTH >= 2) else
      $fatal("DEPTH must be >= 2");
    assert (DATA_WIDTH >= 1) else
      $fatal("DATA_WIDTH must be >= 1");
  end
`endif

  logic rw1_cs_n, rw2_cs_n;
  logic rw1_we_n, rw2_we_n;
  logic rw1_re_n, rw2_re_n;
  logic [ADDR_WIDTH-1:0] rw1_addr, rw2_addr;
  logic [DATA_WIDTH-1:0] rw1_data_in, rw2_data_in;
  logic [DATA_WIDTH-1:0] rw1_data_out, rw2_data_out;

  KW_ram_1rws_dff #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) ram1 (
    .clock   (clock),
    .reset_n (reset_n),
    .cs_n    (rw1_cs_n),
    .we_n    (rw1_we_n),
    .rw_addr (rw1_addr),
    .data_in (rw1_data_in),
    .data_out(rw1_data_out)
  );

  KW_ram_1rws_dff #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) ram2 (
    .clock   (clock),
    .reset_n (reset_n),
    .cs_n    (rw2_cs_n),
    .we_n    (rw2_we_n),
    .rw_addr (rw2_addr),
    .data_in (rw2_data_in),
    .data_out(rw2_data_out)
  );

  KW_dblbuf_cntl #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) cntl (
    .clock(clock),
    .reset_n(reset_n),

    .swap_n(swap_n),

    .w_en_n(w_en_n),
    .w_addr(w_addr),
    .w_data(w_data),

    .r_en_n(r_en_n),
    .r_addr(r_addr),
    .r_data(r_data),

    .rw1_cs_n(rw1_cs_n),
    .rw1_we_n(rw1_we_n),
    .rw1_addr(rw1_addr),
    .rw1_data_in(rw1_data_in),
    .rw1_data_out(rw1_data_out),

    .rw2_cs_n(rw2_cs_n),
    .rw2_we_n(rw2_we_n),
    .rw2_addr(rw2_addr),
    .rw2_data_in(rw2_data_in),
    .rw2_data_out(rw2_data_out)
  );
endmodule
