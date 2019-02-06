module globalbuffer #(
  WGT_DEPTH = 256,
  WGT_WIDTH = 256,
  ACT_DEPTH = 256,
  ACT_WIDTH = 256
) (
  input clock,
  input reset_n,

  // Weight array interface
  input  [WGT_DEPTH-1:0] wgt_addr,
  input                  wgt_ren,
  input                  wgt_wen,
  output [WGT_WIDTH-1:0] wgt_rdata,
  input  [WGT_WIDTH-1:0] wgt_wdata,

  // Activation array interface
  input act_sel, // Buffer select

  input  [ACT_DEPTH-1:0] act_raddr,
  input                  act_ren, // Read enable
  output [ACT_WIDTH-1:0] act_rdata,

  input  [ACT_DEPTH-1:0] act_waddr,
  input                  act_wen, // Write enable
  input  [ACT_WIDTH-1:0] act_wdata
);

floparray wgt_mem #(.DEPTH(WGT_DEPTH),
                    .WIDTH(WGT_WIDTH))
(.clock,
 .reset_n,
 .raddr     (wgt_addr),
 .ren       (wgt_ren),
 .rdata     (wgt_rdata),
 .waddr     (wgt_addr),
 .wen       (wgt_wen),
 .wdata     (wgt_wdata)
)

logic act_ren0, act_ren1, act_wen0, act_wen1;
assign act_ren0 = act_ren & ~act_sel;
assign act_ren1 = act_ren &  act_sel;
assign act_wen0 = act_wen &  act_sel; // Write bank is flipped from read bank
assign act_wen1 = act_wen & ~act_sel;

logic [ACT_WIDTH-1:0] act_rdata0, act_rdata1;
act_rdata = act_sel ? act_rdata1 : act_rdata0;

floparray act_mem0 #(.DEPTH(ACT_DEPTH),
                     .WIDTH(ACT_WIDTH))
(.clock,
 .reset_n,
 .raddr     (act_raddr),
 .ren       (act_ren0),
 .rdata     (act_rdata0),
 .waddr     (act_waddr),
 .wen       (act_wen0),
 .wdata     (act_wdata)
)

floparray act_mem1 #(.DEPTH(ACT_DEPTH),
                     .WIDTH(ACT_WIDTH))
(.clock,
 .reset_n,
 .raddr     (act_raddr),
 .ren       (act_ren1),
 .rdata     (act_rdata1),
 .waddr     (act_waddr),
 .wen       (act_wen1),
 .wdata     (act_wdata)
)

endmodule
