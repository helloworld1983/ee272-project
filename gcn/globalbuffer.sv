module globalbuffer #(
  ACTV_DEPT = 256,
) (
  input clock,
  input reset_n,

  // Weight array interface
  input  wgt_valid,
  input  wgt_wen,
  input  wgt_addr,
  input  wgt_rdata,
  output wgt_wdata,

  // Activation array interface
  input act_ren, // Read enable
  input act_wen, // Write enable
  input act_sel, // Buffer select

  input  act_raddr,
  output act_rdata,

  input  act_waddr,
  input  act_wdata
);

endmodule
