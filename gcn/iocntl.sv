module iocntl (
  input clock,
  input reset_n,

  // Read interface
  input  [ 27:0] rd_addr,
  input          rd_req,
  output         rd_gnt,
  output         rd_valid,
  output [127:0] rd_data,

  // Write interface
  input  [ 27:0] wr_addr,
  input          wr_req,
  output         wr_gnt,
  input  [127:0] wr_data,

  // DRAM interface
  // Note: DRAM fetches 128 bits over 20 cycles
  output [  2:0] io2dram_command,
  output [ 13:0] io2dram_row,
  output [  2:0] io2dram_bank,
  output [  9:0] io2dram_col,
  input  [ 31:0] dram2io_data
);
  typedef enum logic [2:0] {
    CMD_ACTIVATE = 'b011,
    CMD_WRITE    = 'b100,
    CMD_READ     = 'b101,
    CMD_NOP      = 'b111
  } dram_cmd_t;

  // IOCNTL states
  typedef enum logic [3:0] {
    STATE_IDLE, STATE_ACT, STATE_READ, STATE_READ_RESP[3:0]
  } state_t;

  // Buffer for the column address
  logic [9:0] dram_col_buf;

  // State machine
  state_t state, state_next;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      state    <= STATE_IDLE;
      rd_valid <= 1'b0;
      rd_gnt   <= 1'b0;
      wr_gnt   <= 1'b0;
    end else begin
      io2dram_command <= CMD_NOP;
      io2dram_row     <= 'd0;
      io2dram_bank    <= 'd0;
      io2dram_col     <= 'd0;
      rd_gnt          <= 'b0;
      wr_gnt          <= 'b0;
      case (state)
        STATE_IDLE:
          if (rd_req || wr_req) begin
            io2dram_command <= CMD_ACTIVATE;
            io2dram_row     <= rd_addr[26:13];
            io2dram_bank    <= rd_addr[12:10];
            dram_col_buf    <= rd_addr[ 9: 0];
            // Next state is read
            rd_gnt <= 1'b1;
            state  <= STATE_READ;
          end
        STATE_READ: begin
          io2dram_command <= CMD_READ;
          io2dram_col     <= dram_col_buf;
          state           <= STATE_READ_RESP3;
        end
        STATE_READ_RESP3: begin
          io2dram_command <= CMD_NOP;
          rd_data[31:0]   <= dram2io_data;
          state           <= STATE_READ_RESP2;
        end
        STATE_READ_RESP2: begin
          io2dram_command <= CMD_NOP;
          rd_data[63:32]  <= dram2io_data;
          state           <= STATE_READ_RESP1;
        end
        STATE_READ_RESP1: begin
          io2dram_command <= CMD_NOP;
          rd_data[95:64]  <= dram2io_data;
          state           <= STATE_READ_RESP0;
        end
        STATE_READ_RESP0: begin
          io2dram_command <= CMD_NOP;
          rd_data[127:96] <= dram2io_data;
          rd_valid        <= 1'b1;
          state           <= STATE_IDLE;
        end
        default: /* do nothing */;
      endcase
    end
  end
endmodule
