`default_nettype none

module iocntl (
  input wire clock,
  input wire reset_n,

  // Read interface
  input  wire [27:0] rd_addr,
  input  wire        rd_req,
  output reg         rd_gnt,
  output reg         rd_valid,
  output reg [15:0]  rd_data [0:7],

  // Write interface
  input  wire [27:0] wr_addr,
  input  wire        wr_req,
  output reg         wr_gnt,
  input  wire [15:0] wr_data [0:7],

  // RAM address channel
  output reg         cntl2ram_a_valid,
  input  wire        cntl2ram_a_ready,
  output reg         cntl2ram_a_write,
  output reg  [31:0] cntl2ram_a_addr,

  // RAM write data channel
  output reg         cntl2ram_w_valid,
  input  wire        cntl2ram_w_ready,
  output reg  [31:0] cntl2ram_w_data,

  // RAM read data channel
  input  wire        ram2cntl_r_valid,
  output reg         ram2cntl_r_ready,
  input  wire [31:0] ram2cntl_r_data
);
  typedef enum logic [1:0] { STATE_IDLE, STATE_WRITE, STATE_READ } state_t;

  // IO state machine
  state_t state;
  reg [31:0] addr;
  reg [1:0] widx, ridx;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      rd_gnt   <= 1'b0;
      rd_valid <= 1'b0;
      wr_gnt   <= 1'b0;
      state    <= STATE_IDLE;
    end else begin
      case (state)
        STATE_IDLE:
          if (cntl2ram_a_valid && cntl2ram_a_ready) begin
            state <= (rd_req ? STATE_READ : STATE_WRITE);
          end
        STATE_WRITE:
          if (cntl2ram_w_valid && cntl2ram_w_ready) begin
            widx <= widx + 'd1;
            if (widx == 3) begin
              state <= STATE_IDLE;
            end
          end
        STATE_READ:
          if (ram2cntl_r_valid && ram2cntl_r_ready) begin
            {rd_data[2 * ridx + 1], rd_data[2 * ridx]} <= ram2cntl_r_data;
            ridx <= ridx + 'd1;
            if (ridx == 3) begin
              state <= STATE_IDLE;
            end
          end
        default:
          state <= STATE_IDLE;
      endcase
    end
  end

  always_comb begin
    cntl2ram_a_valid = 'b0;
    cntl2ram_a_write = 'b0;
    cntl2ram_a_addr  = 'b0;
    cntl2ram_w_valid = 'b0;
    cntl2ram_w_data  = 'b0;
    ram2cntl_r_ready = 'b0;
    case (state)
      STATE_IDLE: begin
        cntl2ram_a_valid = rd_req || wr_req;
        cntl2ram_a_write = ~rd_req && wr_req;
        cntl2ram_a_addr  = {4'b0, (rd_req ? rd_addr : (wr_req ? wr_addr : 28'b0))};
      end
      STATE_WRITE: begin
        cntl2ram_w_valid = 1'b1;
        cntl2ram_w_data  = {wr_data[2 * widx + 1], wr_data[2 * widx]};
      end
      STATE_READ: begin
        ram2cntl_r_ready = 1'b1;
      end
      default:
        /* nothing */;
    endcase
  end
endmodule
