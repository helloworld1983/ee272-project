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
logic [15:0]  rd_data_UNCONNECTED [0:7];
logic [15:0]  wr_data_UNCONNECTED [0:7];


iocntl
iocntl (
  .*, // Clock/reset_n, rd/wr signals
  // Read interface
  .rd_addr(28'b0),
  .rd_req(1'b0),
  .rd_gnt(),
  .rd_valid(),
  .rd_data(rd_data_UNCONNECTED),
  // Write interface
  .wr_addr(28'b0),
  .wr_req(1'b0),
  .wr_gnt(),
  .wr_data(wr_data_UNCONNECTED),
  // RAM address channel
  .cntl2ram_a_valid(), // FIXME connect with DRAM
  .cntl2ram_a_ready(1'b0), // FIXME connect with DRAM
  .cntl2ram_a_write(), // FIXME connect with DRAM
  .cntl2ram_a_addr(), // FIXME connect with DRAM
  // RAM write data channel
  .cntl2ram_w_valid(), // FIXME connect with DRAM
  .cntl2ram_w_ready(1'b0), // FIXME connect with DRAM
  .cntl2ram_w_data(), // FIXME connect with DRAM
  // RAM read data channel
  .ram2cntl_r_valid(1'b0), // FIXME connect with DRAM
  .ram2cntl_r_ready(), // FIXME connect with DRAM
  .ram2cntl_r_data(32'b0) // FIXME connect with DRAM
);


/* BACKEND */

// -- Internal signals --
// Between dram2gb_cntl and swaparbitrator
logic swap;
// Between dram2gb_cntl and globalbuffer
logic [NUM_WGT_RBANK-1:0][BATCH_SIZE-1:0]                   wgt_raddr;
logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_ren;
logic [NUM_WGT_RBANK-1:0][WGT_WIDTH-1:0]                           wgt_rdata;
logic [NUM_WGT_WBANK-1:0][BATCH_SIZE-1:0]                   wgt_waddr;
logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wen;
logic [NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]                           wgt_wdata;
logic [NUM_ACT_RBANK-1:0][BATCH_SIZE-1:0]                   act_raddr;
logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_ren;
logic [NUM_ACT_RBANK-1:0][ACT_WIDTH-1:0]                           act_rdata;
logic [NUM_ACT_WBANK-1:0][BATCH_SIZE-1:0]                   act_waddr;
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
  .WGT_DEPTH(BATCH_SIZE),
  .WGT_WIDTH(WGT_WIDTH),
  .ACT_DEPTH(BATCH_SIZE),
  .ACT_WIDTH(ACT_WIDTH)
) globalbuffer (
  .*
);

// gb2execute_cntl goes here
gb2execute_cntl gb2execute_cntl
(
    .*
);

execute
execute (
  .*,
  /* Swap control */
  .swap_n(1'b0),
  /* Mac write channel */
  .mac_w_en_n('0),
  .mac_w_col('0),
  .mac_w_addr('0),
  .mac_w_data('0),
  /* Mac input channel */
  .mac_r_en_n('0),
  .mac_r_addr('0),
  .mac_a('0),
  .mac_c('0),
  /* RBuf write control */
  .rbuf_w_addr('0),
  /* RBuf Read channel */
  .rbuf_r_en_n('0),
  .rbuf_r_addr('0),
  .rbuf_r_data()
);


endmodule // gcn.sv
