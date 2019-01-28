// Simple file-backed DRAM module used for testing
// Similar to 8x16Kx1Kx16 (2Gb) DDR with 8n prefetch
module DRAMx32 (
  input clock,
  input reset_n,

  input        io2dram_cs,
  input [ 2:0] io2dram_cmd,
  input [13:0] io2dram_addr,
  input [ 2:0] io2dram_bank,

  inout [15:0] io2dram_data_0,
  inout [15:0] io2dram_data_1
);
  typedef enum logic [2:0] {
    CMD_REFRESH   = 3'b001,
    CMD_PRECHARGE = 3'b010,
    CMD_ACTIVATE  = 3'b011,
    CMD_WRITE     = 3'b100,
    CMD_READ      = 3'b101,
    CMD_NOP       = 3'b111
  } cmd_t;

  typedef enum logic [2:0] {
    DRAM_STATE_IDLE,
    DRAM_STATE_ROW_ACTIVE,
    DRAM_STATE_WRITE,
    DRAM_STATE_READ,
    DRAM_STATE_PRECHARGE,
    DRAM_STATE_ERROR
  } dram_state_t;

  bit [    0:0][128:0][7:0][15:0] memory [0:7] /* verilator public */; // Main memory (8x16MB)
  reg          [128:0][7:0][15:0] page   [0:7]; // Page buffer (8x2KB)

  // Read address into bank/row/col/burst
  wire [13:0] row   = io2dram_addr[13:0];
  wire [ 6:0] col   = io2dram_addr[ 9:3];
  wire [ 2:0] burst = io2dram_addr[ 2:0];
  wire [ 2:0] bank  = io2dram_bank;

  // Burst data
  reg [ 7:0][15:0] rd_fifo; // Read burst fifo (16B)
  reg [15:0] rd_data [0:1];
  reg [ 4:0] rd_cnt; // number of reads performed for current burst
  reg [ 2:0] rd_off; // starting fifo offset for reads

  // Command state machine
  dram_state_t dram_state;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      dram_state <= DRAM_STATE_IDLE;
    end else case (dram_state)
      DRAM_STATE_IDLE:
        // Load the value of the page from memory
        if (io2dram_cmd == CMD_ACTIVATE) begin
          dram_state <= DRAM_STATE_ROW_ACTIVE;
          page[bank] <= memory[bank][row];
        end
      DRAM_STATE_ROW_ACTIVE: begin
        if (io2dram_cmd == CMD_PRECHARGE) begin
          dram_state <= DRAM_STATE_PRECHARGE;
          memory[bank][row] <= page[bank];
        end
        if (io2dram_cmd == CMD_READ) begin
          dram_state <= DRAM_STATE_READ;
          rd_fifo    <= page[bank][col];
          rd_off     <= burst;
          rd_cnt     <= 'd0;
        end
      end
      DRAM_STATE_READ: begin
        if (rd_cnt == 'd6) begin
          dram_state <= DRAM_STATE_IDLE;
        end
        rd_cnt     <= rd_cnt + 'd2;
        rd_data[0] <= rd_fifo[rd_cnt + 0];
        rd_data[1] <= rd_fifo[rd_cnt + 1];
      end
      DRAM_STATE_PRECHARGE:
        dram_state <= DRAM_STATE_IDLE;
      default:
        dram_state <= DRAM_STATE_ERROR;
    endcase
  end

  assign io2dram_data_0 = rd_data[0];
  assign io2dram_data_1 = rd_data[1];
endmodule

// Wrapper module that includes both the IO controller + dram
module tb (
  input clock,
  input reset_n,

  // Read interface
  input  [ 27:0] rd_addr,
  input          rd_req,
  output         rd_gnt,
  output         rd_valid,
  output [ 15:0] rd_data [0:7],

  // Write interface
  input  [ 25:0] wr_addr,
  input          wr_req,
  output         wr_gnt,
  input  [ 15:0] wr_data [0:7]
);
  wire        io2dram_cs;
  wire [ 2:0] io2dram_cmd;
  wire [13:0] io2dram_addr;
  wire [ 2:0] io2dram_bank;
  wire [15:0] io2dram_data_0;
  wire [15:0] io2dram_data_1;

  iocntl io (
    .clock,
    .reset_n,

    .rd_addr,
    .rd_req,
    .rd_gnt,
    .rd_valid,
    .rd_data,

    .wr_addr,
    .wr_req,
    .wr_gnt,
    .wr_data,

    .io2dram_cs,
    .io2dram_cmd,
    .io2dram_addr,
    .io2dram_bank,
    .io2dram_data('{io2dram_data_0, io2dram_data_1})
  );

  DRAMx32 dram (
    .clock,
    .reset_n,

    .io2dram_cs,
    .io2dram_cmd,
    .io2dram_addr,
    .io2dram_bank,
    .io2dram_data_0,
    .io2dram_data_1
  );

  always @(posedge clock) begin
    if (~reset_n) $display("reset");
    else begin
      $display("--");
      case (io2dram_cmd)
        3'b000: $display("ERROR");
        3'b001: $display("REFRESH   : [%H] %H", io2dram_bank, io2dram_addr);
        3'b010: $display("PRECHARGE : [%H] %H", io2dram_bank, io2dram_addr);
        3'b011: $display("ACTIVATE  : [%H] %H", io2dram_bank, io2dram_addr);
        3'b100: $display("WRITE     : [%H] %H", io2dram_bank, io2dram_addr);
        3'b101: $display("READ      : [%H] %H", io2dram_bank, io2dram_addr);
        3'b110: $display("ERROR     : [%H] %H", io2dram_bank, io2dram_addr);
        3'b111: $display("NOP");
      endcase
      if (rd_gnt)   $display("read grant");
      if (wr_gnt)   $display("write grant");
      if (rd_valid) $display("data = [%d, %d]", io2dram_data_0, io2dram_data_1);
    end
  end
endmodule
