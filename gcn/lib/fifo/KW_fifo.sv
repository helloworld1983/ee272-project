`default_nettype none

// A replacement/wrapper for DW_asymfifoctl_s1_sf
module KW_asymfifocntl_s1_sf #(
  parameter int DATA_I_WIDTH = 32, // Must be between 1-256 inclusive
  parameter int DATA_O_WIDTH = 32, // Must be between 1-256 inclusive
  parameter     DEPTH = 16,        // Queue depth
  parameter     AF_LEVEL = 1,      // Almost full level
  parameter     AE_LEVEL = 1,      // Almost empty level

  // Error modes:
  // 0 - Underflow/overflow with pointer latched checking
  // 1 - Underflow/overflow latched checking
  // 2 - Underflow/overflow unlatched checking
  parameter int ERR_MODE = 1,

  // "Hidden" parameters
  parameter int RAM_DATA_WIDTH = DATA_I_WIDTH > DATA_O_WIDTH
                               ? DATA_I_WIDTH : DATA_O_WIDTH,
  parameter int RAM_ADDR_WIDTH = $clog2(DEPTH)
) (
  input wire clock,   // Clock
  input wire reset_n, // Reset, active low, ASYNC

  /* Control */
  input wire push_req_n, // FIFO push request, active low
  input wire pop_req_n,  // FIFO pop request, active low
  input wire flush_n,    // Flush the partial word to memory (fill 0s)
                         // (for DATA_I_WIDTH > DATA_O_WIDTH case only)

  /* Datapath */
  input  wire [DATA_I_WIDTH-1:0] data_in,  // FIFO data to push
  output reg  [DATA_O_WIDTH-1:0] data_out, // FIFO data from pop

  /* Flags */
  output reg empty,        // Asserted when FIFO level == 0
  output reg almost_empty, // Asserted when FIFO level <= AE_LEVEL
  output reg half_full,    // Asserted when FIFO level >= DEPTH / 2
  output reg almost_full,  // Asserted when FIFO level >= (DEPTH – AF_LEVEL)
  output reg full,         // Asserted when FIFO level == DEPTH
  output reg ram_full,     // RAM full, active high
  output reg error,        // FIFO error output, active high

  // Partial word, active high
  // (for data_in_width < data_out_width only; otherwise, tied low)
  output reg part_wr,

  /* RAM interface */
  output wire we_n,  // RAM write enable, active low
  input  wire [RAM_DATA_WIDTH-1:0] rd_data, // RAM read data
  output reg  [RAM_ADDR_WIDTH-1:0] rd_addr, // RAM read address
  output reg  [RAM_DATA_WIDTH-1:0] wr_data, // RAM write data
  output reg  [RAM_ADDR_WIDTH-1:0] wr_addr  // RAM write address
);
  // Parameter check
  initial begin
    assert (DATA_I_WIDTH >= 1 && DATA_I_WIDTH <= 256) else
      $fatal("DATA_I_WIDTH must be in the range [1, 256]");
    assert (DATA_O_WIDTH >= 1 && DATA_O_WIDTH <= 256) else
      $fatal("DATA_O_WIDTH must be in the range [1, 256]");
    assert (DATA_I_WIDTH > DATA_O_WIDTH ?
      DATA_I_WIDTH % DATA_O_WIDTH == 0 : DATA_O_WIDTH % DATA_I_WIDTH == 0) else
      $fatal("DATA_I_WIDTH must be integer multiple of DATA_O_WIDTH");
    assert (DEPTH >= 2 && $clog2(DEPTH) <= 24) else
      $fatal("DEPTH must be in the range [2, 2^24]");
    assert (AE_LEVEL >= 1 && AE_LEVEL < DEPTH) else
      $fatal("AE_LEVEL must be in the range [1, DEPTH)");
    assert (AF_LEVEL >= 1 && AF_LEVEL < DEPTH) else
      $fatal("AF_LEVEL must be in the range [1, DEPTH)");
  end

  // Flags
  reg [$clog2(DEPTH+1)-1:0] count;
  assign empty        = (count == 0);
  assign almost_empty = (count <= AE_LEVEL);
  assign half_full    = (count >= DEPTH / 2);
  assign almost_full  = (count >= (DEPTH - AF_LEVEL));
  assign full         = (count == DEPTH);
  assign ram_full     = (count == DEPTH);
  assign part_wr      = 1'b0;

  // State machine
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      rd_addr <= 'b0;
      wr_addr <= 'b0;
      count   <= 'b0;
    end else begin
      if (~pop_req_n && ~push_req_n) begin
        wr_addr <= wr_addr + 1;
        rd_addr <= rd_addr + 1;
      end else if (~push_req_n) begin
        wr_addr <= wr_addr + 1;
        count   <= count + 1;
      end else if (~pop_req_n) begin
        rd_addr <= rd_addr + 1;
        count   <= count - 1;
      end
    end
  end

  // RAM control
  assign we_n     = push_req_n;
  assign wr_data  = data_in;
  assign data_out = rd_data;

  // Error detection
  generate
    if (ERR_MODE == 0) begin
      initial $fatal("Not implemented");
    end else if (ERR_MODE == 1) begin
      always_ff @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
          error <= 'b0;
        end else begin
          // Error is "sticky" until reset
          error <= error || (~push_req_n && full && pop_req_n) || (~pop_req_n && empty);
        end
      end
    end else if (ERR_MODE == 2) begin
      assign error = (~push_req_n && full && pop_req_n) || (~pop_req_n && empty);
    end
  endgenerate
endmodule

module KW_asymfifo_s1_sf #(
  parameter int DATA_I_WIDTH = 32, // Must be between 1-256 inclusive
  parameter int DATA_O_WIDTH = 32, // Must be between 1-256 inclusive
  parameter     DEPTH = 16,        // Queue depth
  parameter     AF_LEVEL = 1,      // Almost full level
  parameter     AE_LEVEL = 1,      // Almost empty level

  // Error modes:
  // 0 - Underflow/overflow with pointer latched checking
  // 1 - Underflow/overflow latched checking
  // 2 - Underflow/overflow unlatched checking
  parameter int ERR_MODE = 1,

  parameter int RAM_DATA_WIDTH = DATA_I_WIDTH > DATA_O_WIDTH
                               ? DATA_I_WIDTH : DATA_O_WIDTH,
  parameter int RAM_ADDR_WIDTH = $clog2(DEPTH)
) (
  input wire clock,   // Clock
  input wire reset_n, // Reset, active low, ASYNC

  /* Control */
  input wire push_req_n, // FIFO push request, active low
  input wire pop_req_n,  // FIFO pop request, active low
  input wire flush_n,    // Flush the partial word to memory (fill 0s)
                         // (for DATA_I_WIDTH > DATA_O_WIDTH case only)

  /* Datapath */
  input  wire [DATA_I_WIDTH-1:0] data_in,  // FIFO data to push
  output reg  [DATA_O_WIDTH-1:0] data_out, // FIFO data from pop

  /* Flags */
  output reg empty,        // Asserted when FIFO level == 0
  output reg almost_empty, // Asserted when FIFO level <= AE_LEVEL
  output reg half_full,    // Asserted when FIFO level >= DEPTH / 2
  output reg almost_full,  // Asserted when FIFO level >= (DEPTH – AF_LEVEL)
  output reg full,         // Asserted when FIFO level == DEPTH
  output reg ram_full,     // RAM full, active high
  output reg error,        // FIFO error output, active high

  // Partial word, active high
  // (for data_in_width < data_out_width only; otherwise, tied low)
  output reg part_wr
);
  wire we_n;
  reg  [RAM_DATA_WIDTH-1:0] rd_data;
  wire [RAM_ADDR_WIDTH-1:0] rd_addr;
  wire [RAM_DATA_WIDTH-1:0] wr_data;
  wire [RAM_ADDR_WIDTH-1:0] wr_addr;

`ifndef SYNTHESIS
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      $display("RESET");
    end else begin
      if (~push_req_n) $display("Pushing %h @ %h (we_n == %1d)", wr_data, wr_addr, we_n);
      if (~pop_req_n) $display("Popping %h @ %h", ram[rd_addr], rd_addr);
      if (error)      $display("ERROR");
    end
  end
`endif

  reg [RAM_DATA_WIDTH-1:0] ram [0:DEPTH-1];
  always_ff @(posedge clock or negedge reset_n) begin
    if (reset_n) begin
      if (~we_n)
        ram[wr_addr] <= wr_data;
      rd_data <= ram[rd_addr];
    end
  end

  KW_asymfifocntl_s1_sf #(
    .DATA_I_WIDTH  (DATA_I_WIDTH),
    .DATA_O_WIDTH  (DATA_O_WIDTH),
    .DEPTH         (DEPTH),
    .AF_LEVEL      (AF_LEVEL),
    .AE_LEVEL      (AE_LEVEL),
    .ERR_MODE      (ERR_MODE),
    .RAM_DATA_WIDTH(RAM_DATA_WIDTH)
  ) fifo (
    .clock, .reset_n,

    .push_req_n,
    .pop_req_n,
    .flush_n,

    .data_in,
    .data_out,

    .empty,
    .almost_empty,
    .half_full,
    .almost_full,
    .full,
    .ram_full,
    .error,
    .part_wr,

    .we_n,
    .rd_data,
    .rd_addr,
    .wr_data,
    .wr_addr
  );
endmodule
