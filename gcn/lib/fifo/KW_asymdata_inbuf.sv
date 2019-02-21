// A replacement wrapper for DW_asymdata_inbuf
module KW_asymdata_inbuf #(
  parameter int DATA_I_WIDTH = 8,  // Subword size. Must be between 1-2048 inclusive
  parameter int DATA_O_WIDTH = 32, // Word size. Must be between 1-2048 inclusive

  // Value to fill partial words with on flush
  parameter bit FLUSH_VALUE = 0,

  // Sub-word ordering into word
  // 0: The first input sub-word is in th most significant subword of the output
  // 1: The first input sub-word is in the least significant subword of the output
  //
  // For example, if the sequence of pushes is {0, 1, 2}:
  // - For BYTE_ORDER = 0, the output is 012
  // - For BYTE_ORDER = 1, the output is 210
  parameter bit BYTE_ORDER = 0
) (
  input wire clock,   // Clock
  input wire reset_n, // Reset, active low, ASYNC

  /* Input interface */
  input wire push_req_n, // Push request (active low)
  input wire flush_n,    // Flush the partial word (active low)

  /* Output interface */
  input wire fifo_full,  // Full indication connected RAM/FIFO
  output reg push_wd_n,  // Ready to write full data word (active low)

  /* Datapath */
  input  wire [DATA_I_WIDTH-1:0] data_in,  // Input data (sub-word)
  output reg  [DATA_O_WIDTH-1:0] data_out, // Output data (word)

  /* Flags */
  output reg inbuf_full, // Input registers all contain active data_in sub-words
  output reg push_error, // Overrun of RAM/FIFO (includes input registers)
  output reg part_wd     // Partial word pushed flag
);
  localparam int K = DATA_O_WIDTH / DATA_I_WIDTH;
`ifndef SYNTHESIS
  initial begin
    assert (DATA_I_WIDTH >= 1 && DATA_I_WIDTH <= 2048) else
      $fatal("DATA_I_WIDTH must be in the range [1, 256]");
    assert (DATA_O_WIDTH >= 1 && DATA_O_WIDTH <= 2048) else
      $fatal("DATA_O_WIDTH must be in the range [1, 256]");
    assert (DATA_I_WIDTH < DATA_O_WIDTH) else
      $fatal("DATA_I_WIDTH must be less than DATA_O_WIDTH");
    assert (DATA_O_WIDTH % DATA_I_WIDTH == 0) else
      $fatal("DATA_O_WIDTH must be an integer multiple of DATA_I_WIDTH");
    assert (K >= 2) else
      $fatal("DATA_O_WIDTH / DATA_I_WIDTH must be greater or equal to 2");
  end

  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      $display("RESET");
    end else begin
      $display("");
      if (push_error) $display("ERROR");
      $display("flush_n: %d, push_req_n: %d, part_wd: %d, inpbuf_full: %d, fifo_full: %d", flush_n, push_req_n, part_wd, inbuf_full, fifo_full);
      $display("count: %d, next_count: %d", count, next_count);
      if (~push_wd_n)
        $display("inbuf: %h, data_in: %h", inbuf, data_in);
      else
        $display("data_out: invalid");
    end
  end
`endif

  // Buffer/count
  reg [$clog2(K)-1:0] count, next_count;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      count      <= {$clog2(K){1'b0}};
      inbuf_full <= 1'b0;
      part_wd    <= 1'b0;
    end else begin
      // Keep track of count
      count      <= next_count;
      inbuf_full <= next_count == $clog2(K)'(K-1);
      part_wd    <= next_count > 0;
    end
  end

  reg next_error;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      push_error <= 1'b0;
    end else begin
      push_error <= push_error || next_error; // error is "sticky
    end
  end

  reg latch_data;
  reg [$clog2(K)-1:0] latch_addr;
  reg [K-2:0][DATA_I_WIDTH-1:0] inbuf;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      inbuf <= 'b0;
    end else begin
      // Latch data if requested
      if (!push_wd_n) begin
        inbuf <= {(K-1) * DATA_I_WIDTH{FLUSH_VALUE}};
      end
      if (latch_data) begin
        inbuf[latch_addr] <= data_in;
      end
    end
  end

  // Combinational logic
  always_comb begin
    next_count = count;
    next_error = 1'b0;
    push_wd_n  = 1'b1;
    latch_data = 1'b0;
    latch_addr = count;
    casez ({flush_n, push_req_n, part_wd, inbuf_full, fifo_full})
      /* Push request when inbuf is not full */
      5'b10?0?: begin
        // Push only, no error
        next_count = count + 1'b1;
        latch_data = 1'b1;
      end
      /* Flush and push request when buffer is empty */
      5'b0000?: begin
        // Push only, no error
        next_count = count + 1'b1;
        latch_data = 1'b1;
      end
      /* Push request with inbuf full */
      5'b10110: begin
        // generate push_wd_n, reset counters, no error
        next_count = 'b0;
        push_wd_n  = 1'b0;
      end
      /* Push request when inbuf AND fifo full */
      5'b?0111: begin
        // push error, last subword lost, hold counters
        next_error = 1'b1;
      end
      /* Flush request when partial word exists */
      5'b011?0: begin
        // flush only, reset counters, no error
        next_count = 'b0;
        push_wd_n  = 1'b0;
      end
      /* Flush and push request when partial word and fifo not full */
      5'b001?0: begin
        // flush and push (data_in into sub-word1 input reg.), no error
        next_count = 'b1;
        push_wd_n  = 1'b0;
        latch_data = 1'b1;
        latch_addr = 'b0;
      end
      /* Flush request when partial word and fifo full */
      5'b011?1: begin
        // push error, no other action
        next_error = 1'b1;
      end
      /* Flush and push request when partial word and fifo full */
      5'b00101: begin
        // push error, no flush, push data
        next_error = 1'b1;
        push_wd_n  = 1'b0;
      end
      /* No flush or push */
      5'b1100?: /* do nothing */;
      5'b111??: /* do nothing */;
      /* Flush request when no partial word */
      5'b0100?: /* do nothing */;
      5'b??01?: /* not possible */;
    endcase
  end

  generate
    if (BYTE_ORDER == 0) begin
      assign data_out = {<<DATA_I_WIDTH{{data_in, inbuf}}};
    end else begin
      assign data_out = {>>DATA_I_WIDTH{{data_in, inbuf}}};
    end
  endgenerate
endmodule
