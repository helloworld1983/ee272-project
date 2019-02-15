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
  parameter DATA_WIDTH = 32,

  parameter NUM_WGT_RBANK = 1,
  parameter NUM_WGT_WBANK = 1,
  parameter NUM_ACT_RBANK = 2,
  parameter NUM_ACT_WBANK = 1,

  parameter WGT_DEPTH = BATCH_SIZE, // Number of weight entries in global buffer
  parameter WGT_WIDTH = DATA_WIDTH,
  parameter ACT_DEPTH = BATCH_SIZE, // Number of activation entries in global buffer
  parameter ACT_WIDTH = DATA_WIDTH
) (
  input clock,
  input reset_n,

  // Control Signals
  input  process_valid,
  output process_active, // Expects its rising edge to immediately de-assert process_valid
  output process_done,

  // Data Signals
  input  [BATCH_SIZE-1:0][ADDR_WIDTH-1:0] process_raddr,
  output [BATCH_SIZE-1:0][ADDR_WIDTH-1:0] process_waddr
);

/* FRONTEND */
logic [(DATA_WIDTH-1):0] io2dram_data [0:1];

iocntl #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .BATCH_SIZE(BATCH_SIZE)
) iocntl (
  .*, // Clock/reset_n, rd/wr signals
  .io2dram_cs(), // FIXME connect with DRAM
  .io2dram_cmd(), // FIXME connect with DRAM
  .io2dram_addr(), // FIXME connect with DRAM
  .io2dram_bank(), // FIXME connect with DRAM
  .io2dram_data(io2dram_data) // FIXME connect with DRAM
);


/* BACKEND */

// -- Internal signals --
// Between dram2gb_cntl and swaparbitrator
logic swap;
// Between dram2gb_cntl and globalbuffer
logic [NUM_WGT_RBANK-1:0][$clog2(WGT_DEPTH)-1:0]                   wgt_raddr;
logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_ren;
logic [NUM_WGT_RBANK-1:0][WGT_WIDTH-1:0]                           wgt_rdata;
logic [NUM_WGT_WBANK-1:0][$clog2(WGT_DEPTH)-1:0]                   wgt_waddr;
logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wen;
logic [NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]                           wgt_wdata;
logic [NUM_ACT_RBANK-1:0][$clog2(ACT_DEPTH)-1:0]                   act_raddr;
logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_ren;
logic [NUM_ACT_RBANK-1:0][ACT_WIDTH-1:0]                           act_rdata;
logic [NUM_ACT_WBANK-1:0][$clog2(ACT_DEPTH)-1:0]                   act_waddr;
logic [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wen;
logic [NUM_ACT_WBANK-1:0][ACT_WIDTH-1:0]                           act_wdata;
// Between dram2gb_cntl and iocntl
logic [(ADDR_WIDTH-1):0] rd_addr;
logic                    rd_req;
logic                    rd_gnt;
logic                    rd_valid;
logic [(DATA_WIDTH-1):0] rd_data [0:(BATCH_SIZE-1)];
logic [(ADDR_WIDTH-1):0] wr_addr;
logic                    wr_req;
logic                    wr_gnt;
logic [(DATA_WIDTH-1):0] wr_data [0:(BATCH_SIZE-1)];
// Between swaparbitrator and globalbuffer
logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel;
logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel;
logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel;
logic [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel;
// Between macarray and dram2gb_cntl
logic mac_done; // FIXME: connect to mac array

assign process_done = mac_done;

dram2gb_cntl 
#(
  .BATCH_SIZE(BATCH_SIZE),
  .ADDR_WIDTH(ADDR_WIDTH),
  .NUM_WGT_RBANK(NUM_WGT_RBANK),
  .NUM_WGT_WBANK(NUM_WGT_WBANK),
  .NUM_ACT_RBANK(NUM_ACT_RBANK),
  .NUM_ACT_WBANK(NUM_ACT_WBANK),
  .WGT_DEPTH(WGT_DEPTH),
  .WGT_WIDTH(WGT_WIDTH),
  .ACT_DEPTH(ACT_DEPTH),
  .ACT_WIDTH(ACT_WIDTH)
) dram2gb_cntl (
  .*
);

swaparbitrator
#(
  .NUM_WGT_RBANK(NUM_WGT_RBANK),
  .NUM_WGT_WBANK(NUM_WGT_WBANK),
  .NUM_ACT_RBANK(NUM_ACT_RBANK),
  .NUM_ACT_WBANK(NUM_ACT_WBANK)
) swaparbitrator (
  .*
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
  .*
);

endmodule // gcn.sv
