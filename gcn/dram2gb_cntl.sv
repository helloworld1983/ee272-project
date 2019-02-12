// Control logic to synchronize DRAM + global memory
module dram2gb_cntl #(
  parameter WGT_DEPTH = 256,
  parameter WGT_WIDTH = 256,
  parameter ACT_DEPTH = 256,
  parameter ACT_WIDTH = 256

) (
  input clock,
  input reset_n,

  // Control interface

  // --- DRAM interface ---
  // Read interface
  output [27:0] rd_addr,
  output        rd_req,
  input         rd_gnt,
  input         rd_valid,
  input  [15:0] rd_data [0:7],

  // Write interface
  output [25:0] wr_addr,
  output        wr_req,
  input         wr_gnt,
  output [15:0] wr_data [0:7],

  // DRAM interface (Note: DRAM fetches 128 bits over 20 cycles)
  input         io2dram_cs,
  input  [ 2:0] io2dram_cmd,
  input  [13:0] io2dram_addr,
  input  [ 2:0] io2dram_bank,
  output [15:0] io2dram_data [0:1],

  // --- Global Buffer interface ---
  // Weight array interface
  output [NUM_WGT_RBANK-1:0][WGT_DEPTH-1:0]                          wgt_raddr,
  output [NUM_WGT_RBANK-1:0][$clog(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel,
  output [NUM_WGT_RBANK-1:0][$clog(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_ren,
  input  [NUM_WGT_RBANK-1:0][WGT_WIDTH-1:0]                          wgt_rdata,

  output [NUM_WGT_WBANK-1:0][WGT_DEPTH-1:0]                          wgt_waddr,
  output [NUM_WGT_WBANK-1:0][$clog(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel,
  output [NUM_WGT_WBANK-1:0][$clog(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wen,
  output [NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]                          wgt_wdata,

  // Activation array interface
  output [NUM_ACT_RBANK-1:0][ACT_DEPTH-1:0]                          act_raddr,
  output [NUM_ACT_RBANK-1:0][$clog(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel,
  output [NUM_ACT_RBANK-1:0][$clog(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_ren,
  input  [NUM_ACT_RBANK-1:0][ACT_WIDTH-1:0]                          act_rdata,

  output [NUM_ACT_WBANK-1:0][ACT_DEPTH-1:0]                          act_waddr,
  output [NUM_ACT_WBANK-1:0][$clog(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel,
  output [NUM_ACT_WBANK-1:0][$clog(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wen,
  output [NUM_ACT_WBANK-1:0][ACT_WIDTH-1:0]                          act_wdata
);

// Goal: Parallelize the DRAM fetch/write and GB fetch/write.
//
// Solution: Have two FSMs with dependencies.
// 
// GB should have 2 read banks and 1 write bank.
// - At once, 1 rd/wr bank pair are actively processing data with the MAC array.
//   The other write bank is writing back to DRAM memory, then loading in the next set of wgt/act
//   values.
// - At every node completion, the write bank becomes the dram bank, the DRAM bank becomes the read
//   bank, and the original read bank becomes the write bank.
//   (^ This applies to the activations. Since weight banks are only reads, only two are needed, and
//      they are swapped upon node completion)
// Node completion is defined as: when both DRAM and GB are completed.

  typedef enum logic [1:0] {
    STATE_GB_IDLE, STATE_GB_ACTIVE, STATE_GB_DONE
  } state_gb_t;

  typedef enum logic [2:0] {
    STATE_DRAM_IDLE, STATE_DRAM_WRITEBACK, STATE_DRAM_LOAD, STATE_DRAM_SWAP, STATE_DRAM_WAIT
  } state_dram_t;

  logic gb_rdy, dram_rdy;

  // GB State machine
  state_gb_t state_gb, state_gb_next;
  always_ff @ (posedge clock) begin
    if (~reset_n) begin
      state_gb <= STATE_GB_IDLE;
    end
    else begin
      state_gb <= state_gb_next;
    end
  end

  always_comb begin
    gb_rdy = 1'b0;

    case(state)
      STATE_GB_IDLE: begin
        // wait for valid data to come in from dram
        gb_rdy = 1'b1;
        if (node_valid)
          state_gb_next = STATE_GB_ACTIVE;
      end
      STATE_GB_ACTIVE: begin
        // process data
        if (node_complete)
          state_gb_next = STATE_GB_DONE;
      end
      STATE_GB_DONE: begin
        // wait for dram to also be done/idle: output ready to swap banks and initiate writing back to dram/starting new node
        gb_rdy = 1'b1;
        if (dram_rdy | node_valid) begin
          swap = 1'b1;
          state_gb_next = STATE_GB_ACTIVE;
        end
        else if (dram_rdy | ~node_valid) begin
          swap = 1'b1;
          state_gb_next = STATE_GB_IDLE;
      end
      default: /* do nothing */
    endcase
  end


  // DRAM State machine
  stage_dram_t state_dram, state_dram_next;
  always_ff @ (posedge clock) begin
    if (~reset_n) begin
      state_dram <= STATE_DRAM_IDLE;
    end
    else begin
      state_dram <= state_dram_next;
    end
  end

  always_comb begin
    dram_rdy = 1'b0;

    case(state)
      STATE_DRAM_IDLE: begin
        // Wait for request to process new load
        dram_rdy = 1'b1;
        if (rd_req)
          state_dram_next = STATE_DRAM_LOAD;
      end
      STATE_DRAM_WRITEBACK: begin
        // Write back to DRAM
        if (wr_done) begin
          if (rd_req)
            state_dram_next = STATE_DRAM_LOAD;
          else
            state_dram_next = STATE_DRAM_IDLE;
        end
      end
      STATE_DRAM_LOAD: begin
        // Load from DRAM
        if (ld_done)
          if (gb_rdy)
            state_dram_next = STATE_DRAM_SWAP;
          else
            state_dram_next = STATE_DRAM_WAIT;
      end
      STATE_DRAM_WAIT: begin
        // Wait for global buffer to be done/idle
        dram_rdy = 1'b1;
        if (gb_rdy) begin
          state_dram_next = STATE_DRAM_SWAP;
        end
      end
      STATE_DRAM_SWAP: begin
        swap = 1'b1;
        if (wr_req)
          state_dram_next = STATE_DRAM_WRITEBACK;
        else
          state_dram_next = STATE_DRAM_IDLE;
      end
      default: /* do nothing */
    endcase
  end

endmodule // dram2gb_cntl
