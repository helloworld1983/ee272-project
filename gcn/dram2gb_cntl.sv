// Control logic to synchronize DRAM + global memory
module dram2gb_cntl #(
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
  input  clock,
  input  reset_n,

  // -- Interface with internal FSM
  input  mac_done,       // MAC array :: 1-cycle pulse when MAC is completed
  output swap,           // Swap Arb :: Swap banks for weights/activations
  input  process_valid,  // Asserted when valid batch is waiting to be processed. De-asserts upon process_active rising edge.
  output process_active, // Asserted when MAC is processing

  // MISC
  // -- Interface with CPU --
  input  [BATCH_SIZE-1:0][ADDR_WIDTH-1:0] process_raddr,
  output [BATCH_SIZE-1:0][ADDR_WIDTH-1:0] process_waddr,

  // -- Interface with GB --
  // Weight array interface
  output [NUM_WGT_RBANK-1:0][$clog2(WGT_DEPTH)-1:0]                   wgt_raddr,
  output [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel, // Swap Arb :: know which index to assert
  output [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_ren,
  input  [NUM_WGT_RBANK-1:0][WGT_WIDTH-1:0]                           wgt_rdata,

  output [NUM_WGT_WBANK-1:0][$clog2(WGT_DEPTH)-1:0]                   wgt_waddr,
  output [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel, // Swap Arb :: know which index to assert
  output [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wen,
  output [NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]                           wgt_wdata,

  // Activation array interface
  output [NUM_ACT_RBANK-1:0][$clog2(ACT_DEPTH)-1:0]                   act_raddr,
  output [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel, // Swap Arb :: know which index to assert
  output [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_ren,
  input  [NUM_ACT_RBANK-1:0][ACT_WIDTH-1:0]                           act_rdata,

  output [NUM_ACT_WBANK-1:0][$clog2(ACT_DEPTH)-1:0]                   act_waddr,
  output [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel, // Swap Arb :: know which index to assert
  output [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wen,
  output [NUM_ACT_WBANK-1:0][ACT_WIDTH-1:0]                           act_wdata,

  // -- Interface with DRAM --
  // Read interface
  output [(ADDR_WIDTH-1):0] rd_addr,
  output                    rd_req,
  input                     rd_gnt,
  input                     rd_valid,
  input  [(DATA_WIDTH-1):0] rd_data [0:(BATCH_SIZE-1)],

  // Write interface
  output [(ADDR_WIDTH-1):0] wr_addr,
  output                    wr_req,
  input                     wr_gnt,
  output [(DATA_WIDTH-1):0] wr_data [0:(BATCH_SIZE-1)]
);

logic writeback_gnt;
logic writeback_req;

logic writeback_done;
logic writeback_active;


logic load_done;
logic load_active;

// Retain knowledge of whether or not MAC had finished processing without writing back.
always_ff @ (posedge clock) begin
  if (~reset_n)           writeback_req <= 1'b0;
  else if (mac_done)      writeback_req <= 1'b1;
  else if (writeback_gnt) writeback_req <= 1'b0;
end

// Arbitrate the address writing out to DRAM


// Arbitrate the address writing to SRAM

dram2gb_stcntl dram2gb_stcntl
(
  .*, // Clock/reset_n

  // FIXME: temp tie-offs to compile, need to make correct connections
  .mac_done,
  .swap,
  .process_valid,
  .process_active,

  .writeback_req, // UNUSED ATM
  .writeback_gnt,
  .writeback_done('0), // FIXME
  .writeback_active(), // FIXME
  .load_done('0), // FIXME
  .load_active() // FIXME
);


  
endmodule // dram2gb_cntl
