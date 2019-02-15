// Control logic to synchronize DRAM + global memory
module dram2gb_cntl
(
  input  clock,
  input  reset_n,

  // GB FSM
  input  mac_done,
  input  process_valid,  // Asserted when valid batch is waiting to be processed. De-asserts upon process_active rising edge.
  output process_active, // Asserted when MAC is processing

  // DRAM FSM
  input  writeback_req,
  input  writeback_done,
  output writeback_active,
  input  load_done,
  output load_active,
  output swap            // Swap banks for weights/activations
);

// -------------------------------------------------------------------------------------------------------------------
// Goal: Parallelize the DRAM fetch/write and GB fetch/write.
// Solution: Two separate but interlocked FSMs. The interlocking step is at the IDLE of both FSMs.
// 
// Details: ACTIVATION has 2 read banks and 1 write bank in the Global Buffer.
// - At once, 1 rd/wr bank pair are actively processing data with the MAC array.
//   The other write bank is writing back to DRAM memory, then loading in the next set of wgt/act values.
// - At every node completion, the write bank becomes the dram bank, the DRAM bank becomes the read
//   bank, and the original read bank becomes the write bank.
// -------------------------------------------------------------------------------------------------------------------

  typedef enum logic [1:0] {
    STATE_GB_IDLE, STATE_GB_ACTIVE, STATE_GB_DONE
  } state_gb_t;

  typedef enum logic [1:0] {
    STATE_DRAM_IDLE, STATE_DRAM_WRITEBACK, STATE_DRAM_LOAD, STATE_DRAM_SWAP
  } state_dram_t;

  logic gb_idle, gb_idle_q, dram_idle, dram_idle_q;
  always_ff @ (posedge clock) begin
    if (~reset_n) begin
      gb_idle_q <= 1'b0;
      dram_idle_q <= 1'b0;
    end
    else begin
      gb_idle_q <= gb_idle;
      dram_idle_q <= dram_idle;
    end
  end


  logic dram_loaded, dram_loaded_deassert, dram_loaded_assert;
  always_ff @ (posedge clock) begin
    if (~reset_n || dram_loaded_deassert) dram_loaded <= 1'b0;
    else if (dram_loaded_assert)          dram_loaded <= 1'b1;
  end

  // GB State machine: This only controls the processing.
  // Process when weight/activation banks are ready
  state_gb_t state_gb, state_gb_next;
  always_ff @ (posedge clock) begin
    if (~reset_n) state_gb <= STATE_GB_IDLE;
    else          state_gb <= state_gb_next;
  end

  always_comb begin
    // Internal signals
    gb_idle = 1'b0;
    // Output signals
    process_active = 1'b0;

    case(state_gb)
      STATE_GB_IDLE: begin
        // Wait for valid data to be loaded from DRAM
        gb_idle = 1'b1;
        if (process_valid & dram_loaded) state_gb_next = STATE_GB_ACTIVE;
        else                             state_gb_next = STATE_GB_IDLE;
      end
      STATE_GB_ACTIVE: begin
        // Process data
        process_active = 1'b1;
        if (mac_done) state_gb_next = STATE_GB_DONE;
        else          state_gb_next = STATE_GB_ACTIVE;
      end
      STATE_GB_DONE: begin
        // Wait for DRAM to also be done/idle.
        gb_idle = 1'b1;
        if (dram_idle_q | process_valid)       state_gb_next = STATE_GB_ACTIVE;
        else if (dram_idle_q | ~process_valid) state_gb_next = STATE_GB_IDLE;
        else                                 state_gb_next = STATE_GB_DONE;
      end
      default: begin /* do nothing */ end
    endcase

  end

  // DRAM State machine
  state_dram_t state_dram, state_dram_next;
  always_ff @ (posedge clock) begin
    if (~reset_n) state_dram <= STATE_DRAM_IDLE;
    else          state_dram <= state_dram_next;
  end

  always_comb begin
    // Internal signals
    dram_idle = 1'b0;
    dram_loaded_deassert = 1'b0;
    dram_loaded_assert = 1'b0;
    // Output signals
    writeback_active = 1'b0;
    load_active = 1'b0;

    case(state_dram)
      STATE_DRAM_IDLE: begin
        // Wait for request to process new load
        dram_idle = 1'b1;
        if      (process_valid &  dram_loaded & gb_idle_q) state_dram_next = STATE_DRAM_SWAP;
        else if (process_valid & ~dram_loaded & gb_idle_q) state_dram_next = STATE_DRAM_LOAD;
        else                                             state_dram_next = STATE_DRAM_IDLE;
      end
      STATE_DRAM_SWAP: begin
        // Swap banks (can probably consolidate)
        swap = 1'b1; // 1-cycle pulse: Signals writeback
        dram_loaded_deassert = 1'b1; // 1-cycle pulse
        if (writeback_req) state_dram_next = STATE_DRAM_WRITEBACK;
        else               state_dram_next = STATE_DRAM_IDLE;
      end
      STATE_DRAM_LOAD: begin
        // Load from DRAM
        load_active = 1'b1;
        if (load_done) begin
          dram_loaded_assert = 1'b1; // 1-cycle pulse
          state_dram_next = STATE_DRAM_IDLE;
        end
        else state_dram_next = STATE_DRAM_LOAD;
      end
      STATE_DRAM_WRITEBACK: begin
        // Write back to DRAM
        writeback_active = 1'b1;
        if (writeback_done) begin
          if (process_valid) state_dram_next = STATE_DRAM_LOAD;
          else               state_dram_next = STATE_DRAM_IDLE;
        end
        else state_dram_next = STATE_DRAM_WRITEBACK;
      end
      default: begin /* do nothing */ end
    endcase
  end

  /* ASSERTIONS */
  // ~dram_loaded when STATE_DRAM_WRITEBACK

  
endmodule // dram2gb_cntl
