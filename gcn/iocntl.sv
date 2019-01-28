// A 'toy' version of a x16 DRAM interface with 8n prefetch
// This is NOT a real DRAM interface, only used for simple experimentation
module iocntl (
  input clock,
  input reset_n,

  // Read interface
  input  [27:0] rd_addr,
  input         rd_req,
  output        rd_gnt,
  output        rd_valid,
  output [15:0] rd_data [0:7],

  // Write interface
  input  [25:0] wr_addr,
  input         wr_req,
  output        wr_gnt,
  input  [15:0] wr_data [0:7],

  // DRAM interface
  // Note: DRAM fetches 128 bits over 20 cycles
  output        io2dram_cs,
  output [ 2:0] io2dram_cmd,
  output [13:0] io2dram_addr,
  output [ 2:0] io2dram_bank,
  input  [15:0] io2dram_data [0:1]
);
  parameter BAD_ADDR = 14'h3BAD;

  typedef enum logic [2:0] {
    CMD_REFRESH   = 3'b001,
    CMD_PRECHARGE = 3'b010,
    CMD_ACTIVATE  = 3'b011,
    CMD_WRITE     = 3'b100,
    CMD_READ      = 3'b101,
    CMD_NOP       = 3'b111
  } dram_cmd_t;

  // IOCNTL states
  typedef enum logic [3:0] {
    STATE_IDLE, STATE_ACT, STATE_READ, STATE_READ_RESP[5:0]
  } state_t;

  // Buffer for the column address
  logic [9:0] col_ff;
  logic [2:0] active_bank;

  // State machine
  state_t state, state_next;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      state        <= STATE_IDLE;
      io2dram_cmd  <= CMD_NOP;
      io2dram_addr <= BAD_ADDR;
      io2dram_bank <= 'd0;
      rd_valid     <= 1'b0;
      rd_gnt       <= 1'b0;
      wr_gnt       <= 1'b0;
    end else begin
      io2dram_cmd  <= CMD_NOP;
      io2dram_addr <= BAD_ADDR;
      io2dram_bank <= 'd0;
      rd_valid     <= 1'b0;
      rd_gnt       <= 1'b0;
      wr_gnt       <= 1'b0;
      case (state)
        STATE_IDLE:
          if (rd_req) begin
            io2dram_cmd   <= CMD_ACTIVATE;
            io2dram_addr  <= rd_addr[26:13];
            io2dram_bank  <= rd_addr[12:10];
            // Buffer the column/bank for next read
            active_bank   <= rd_addr[12:10];
            col_ff        <= rd_addr[ 9: 0];
            // Next state is read
            rd_gnt <= 1'b1;
            state  <= STATE_READ;
          end
        STATE_READ: begin
          io2dram_cmd  <= CMD_READ;
          io2dram_addr <= {4'b0000, col_ff};
          io2dram_bank <= active_bank;
          state        <= STATE_READ_RESP5;
        end
        STATE_READ_RESP5: begin
          /* Wait state */
          io2dram_cmd  <= CMD_NOP;
          state        <= STATE_READ_RESP4;
        end
        STATE_READ_RESP4: begin
          /* Wait state */
          io2dram_cmd <= CMD_NOP;
          state       <= STATE_READ_RESP3;
        end
        STATE_READ_RESP3: begin
          io2dram_cmd <= CMD_NOP;
          rd_data[0]  <= io2dram_data[0];
          rd_data[1]  <= io2dram_data[1];
          state       <= STATE_READ_RESP2;
        end
        STATE_READ_RESP2: begin
          io2dram_cmd <= CMD_NOP;
          rd_data[2]  <= io2dram_data[0];
          rd_data[3]  <= io2dram_data[1];
          state       <= STATE_READ_RESP1;
        end
        STATE_READ_RESP1: begin
          io2dram_cmd <= CMD_NOP;
          rd_data[4]  <= io2dram_data[0];
          rd_data[5]  <= io2dram_data[1];
          state       <= STATE_READ_RESP0;
        end
        STATE_READ_RESP0: begin
          io2dram_cmd <= CMD_NOP;
          rd_data[6]  <= io2dram_data[0];
          rd_data[7]  <= io2dram_data[1];
          rd_valid    <= 1'b1;
          state       <= STATE_IDLE;
        end
        default: /* do nothing */;
      endcase
    end
  end

  // CS is always held high
  assign io2dram_cs = 1'b1;
endmodule
