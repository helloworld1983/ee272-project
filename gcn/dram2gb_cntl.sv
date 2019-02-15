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
  output [NUM_WGT_RBANK-1:0][BATCH_SIZE-1:0]                          wgt_raddr,
  output [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel, // Swap Arb :: know which index to assert
  output [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_ren,
  input  [NUM_WGT_RBANK-1:0][WGT_WIDTH-1:0]                           wgt_rdata,

  output [NUM_WGT_WBANK-1:0][BATCH_SIZE-1:0]                          wgt_waddr,
  output [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel, // Swap Arb :: know which index to assert
  output [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wen,
  output [NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]                           wgt_wdata,

  // Activation array interface
  output [NUM_ACT_RBANK-1:0][BATCH_SIZE-1:0]                          act_raddr,
  output [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel, // Swap Arb :: know which index to assert
  output [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_ren,
  input  [NUM_ACT_RBANK-1:0][ACT_WIDTH-1:0]                           act_rdata,

  output [NUM_ACT_WBANK-1:0][BATCH_SIZE-1:0]                          act_waddr,
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
logic writeback_active, writeback_active_q;
logic load_done;
logic load_active, load_active_q;

// Retain knowledge of whether or not MAC had finished processing without writing back.
always_ff @ (posedge clock) begin
  if (~reset_n)           writeback_req <= 1'b0;
  else if (mac_done)      writeback_req <= 1'b1;
  else if (writeback_gnt) writeback_req <= 1'b0;
end

/* MEMORY INTERFACING LOGIC */
// Static indices for each bank (Value is assigned by swap abritrator)
localparam WGT_MAC_RD_BANK = 0;
localparam WGT_MAC_WR_BANK = 1;

localparam ACT_MAC_RD_BANK = 0;
localparam ACT_MAC_WR_BANK = 1;
localparam ACT_DRAM_BANK   = 2;

logic [BATCH_SIZE*2-1:0] load_counter; // x2 because need to load both weights and activations
logic [BATCH_SIZE-1:0]   writeback_counter;
logic load_rise, writeback_rise;

always_ff @ (posedge clock) begin
  if (~reset_n) begin
    load_active_q <= '0;
    writeback_active_q <= '0;
  end
  else begin
    load_active_q <= load_active;
    writeback_active_q <= writeback_active;
  end
end
assign load_rise = load_active & ~load_active_q;
assign writeback_rise = writeback_active & ~writeback_active_q;

always_ff @ (posedge clock) begin
  if (~reset_n | load_rise | ~load_active | load_done)
    load_counter <= '0;
  else
    load_counter <= load_counter + 1'b1;
end
always_ff @ (posedge clock) begin
  if (~reset_n | writeback_rise | ~writeback_active | writeback_done)
    writeback_counter <= '0;
  else
    writeback_counter <= writeback_counter + 1'b1;
end

// FIXME
// 1. Activations get written from DRAM -> GB. Index the ADDR with the load counter.
// 2. Weights get written from DRAM -> GB. Index the ADDR with the load counter - BATCH_SIZE
always_ff @ (posedge clock) begin
  if (load_active && (load_counter < BATCH_SIZE)) begin
    rd_addr <= process_raddr[0]; //[load_counter];
    act_waddr[ACT_MAC_RD_BANK] <= load_counter[BATCH_SIZE-1:0];
    act_wen[ACT_MAC_RD_BANK] <= act_wsel[ACT_MAC_RD_BANK];
    act_wdata[ACT_MAC_RD_BANK] <= rd_data[0]; //[load_counter[BATCH_SIZE-1:0]];
  end
  else if (load_active) begin
    rd_addr <= process_raddr[0]; //[load_counter-BATCH_SIZE];
    wgt_waddr[WGT_MAC_RD_BANK] <= load_counter[BATCH_SIZE-1:0]-BATCH_SIZE;
    act_wen[WGT_MAC_RD_BANK] <= {1'b0,wgt_wsel[0]}; //[WGT_MAC_RD_BANK];
    act_wdata[WGT_MAC_RD_BANK] <= rd_data[0]; //[load_counter[BATCH_SIZE-1:0]-BATCH_SIZE];
  end
end

always_ff @ (posedge clock) begin
  if (writeback_active) begin
    // Activations get written from GB -> DRAM
    wr_addr <= process_waddr[0]; //[load_counter];
    act_raddr[ACT_MAC_RD_BANK] <= load_counter[BATCH_SIZE-1:0];
    act_ren <= {2'b0,act_rsel[0]}; //[ACT_MAC_RD_BANK];
    wr_data[0] <= act_rdata[0]; //[load_counter[BATCH_SIZE-1:0]];
  end
end

assign writeback_done = (|writeback_counter) ? 1'b1 : 1'b0;
assign load_done      = (|load_counter)      ? 1'b1 : 1'b0;

dram2gb_stcntl dram2gb_stcntl
(
  .*, // Clock/reset_n

  .mac_done,
  .swap,
  .process_valid,
  .process_active,

  .writeback_req, // UNUSED ATM
  .writeback_gnt,
  .writeback_done,
  .writeback_active,
  .load_done,
  .load_active
);


  
endmodule // dram2gb_cntl
