// -------------------------------------------------------------------------------------------------------------------
// Top-level module for GCN
//
// -Modules-
//  Front-End:
//  - TODO
//
//  Back-End:
//  - swaparbitrator
//  - globalbuffer
//  - dram2gb_cntl (TODO)
//  - macarray (TODO)
// -------------------------------------------------------------------------------------------------------------------
module gcn #(
  parameter BATCH_SIZE = 128, // Number of distinct addresses accessed per process batch
  parameter ADDR_WIDTH = 32,

  parameter NUM_WGT_RBANK = 1,
  parameter NUM_WGT_WBANK = 1,
  parameter NUM_ACT_RBANK = 2,
  parameter NUM_ACT_WBANK = 1,

  parameter WGT_DEPTH = BATCH_SIZE, // Number of weight entries in global buffer
  parameter WGT_WIDTH = 256,
  parameter ACT_DEPTH = BATCH_SIZE, // Number of activation entries in global buffer
  parameter ACT_WIDTH = 256
) (
  input clock,
  input reset_n,

  // Control Signals
  input req,
  output ack,
  output done,

  // Data Signals
  input [BATCH_SIZE-1:0][ADDR_WIDTH-1:0] rd_addr,
  output [BATCH_SIZE-1:0][ADDR_WIDTH-1:0] wr_addr
);

/* FRONTEND */

/* BACKEND */

// -- Internal signals --
// Between dram2gb_cntl and swaparbitrator
logic swap;
// Between dram2gb_cntl and globalbuffer
// Between swaparbitrator and globalbuffer
logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel;
logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel;
logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel;
logic [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel;

dram2gb_cntl dram2gb_cntl
(
  .*,
  // FIXME: temp tie-offs to compile, need to make correct connections
  .mac_done('0),
  .process_valid('0),
  .process_active(),
  .writeback_req('0),
  .writeback_done('0),
  .writeback_active(),
  .load_done('0),
  .load_active()
);

swaparbitrator
#(
  .NUM_WGT_RBANK(NUM_WGT_RBANK),
  .NUM_WGT_WBANK(NUM_WGT_WBANK),
  .NUM_ACT_RBANK(NUM_ACT_RBANK),
  .NUM_ACT_WBANK(NUM_ACT_WBANK)
) swaparbitrator (
  .*,
);

globalbuffer
#(
  .NUM_WGT_RBANK(NUM_WGT_RBANK),
  .NUM_WGT_WBANK(NUM_WGT_WBANK),
  .NUM_ACT_RBANK(NUM_ACT_RBANK),
  .NUM_ACT_WBANK(NUM_ACT_WBANK),
  .WGT_DEPTH(WGT_DEPTH),
  .WGT_WIDTH(WGT_WIDTH),
  .ACT_DEPTH(ACT_DEPTH),
  .ACT_WIDTH(ACT_WIDTH)
) globalbuffer (
  .*,
 // FIXME: temp tie-offs to compile, need to make correct connections
  .wgt_raddr('0),
  .wgt_ren('0),
  .wgt_rdata(),
  .wgt_waddr('0),
  .wgt_wen('0),
  .wgt_wdata(),
  .act_raddr('0),
  .act_ren('0),
  .act_rdata(),
  .act_waddr('0),
  .act_wen('0),
  .act_wdata()
);

endmodule // gcn.sv
