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
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      rd_gnt   <= 1'b0;
      rd_valid <= 1'b0;
      wr_gnt   <= 1'b0;
    end else begin
    end
  end
endmodule
