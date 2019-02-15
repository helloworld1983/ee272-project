`default_nettype none

module tb (
  input wire clock,
  input wire reset_n,

  // Read interface
  input  wire [27:0] rd_addr,
  input  wire        rd_req,
  output wire        rd_gnt,
  output reg         rd_valid,
  output reg [15:0]  rd_data [0:7],

  // Write interface
  input  wire [27:0] wr_addr,
  input  wire        wr_req,
  output reg         wr_gnt,
  input  wire [15:0] wr_data [0:7]
);
  localparam int ADDR_BITS = 32;
  localparam int DATA_BITS = 32;

  wire                 cntl2ram_a_valid;
  wire                 cntl2ram_a_ready;
  wire                 cntl2ram_a_write;
  wire [ADDR_BITS-1:0] cntl2ram_a_addr;

  wire                 cntl2ram_w_valid;
  wire                 cntl2ram_w_ready;
  wire [DATA_BITS-1:0] cntl2ram_w_data;

  wire                 ram2cntl_r_valid;
  wire                 ram2cntl_r_ready;
  wire [DATA_BITS-1:0] ram2cntl_r_data;
  ram #(
    .ADDR_BITS(ADDR_WIDTH),
    .DATA_BITS(DATA_WIDTH)
  ) ram_inst (
    .clock, .reset_n,

    .a_valid(cntl2ram_a_valid),
    .a_ready(cntl2ram_a_ready),
    .a_write(cntl2ram_a_write),
    .a_addr (cntl2ram_a_addr),

    .w_valid(cntl2ram_w_valid),
    .w_ready(cntl2ram_w_ready),
    .w_data (cntl2ram_w_data),

    .r_valid(ram2cntl_r_valid),
    .r_ready(ram2cntl_r_ready),
    .r_data (ram2cntl_r_data)
  );

  iocntl iocntl_inst (
    .clock, .reset_n,

    .rd_addr (rd_addr),
    .rd_req  (rd_req),
    .rd_gnt  (rd_gnt),
    .rd_valid(rd_valid),
    .rd_data (rd_data),

    .wr_addr (wr_addr),
    .wr_req  (wr_req),
    .wr_gnt  (wr_gnt),
    .wr_data (wr_data),

    .cntl2ram_a_valid,
    .cntl2ram_a_ready,
    .cntl2ram_a_write,
    .cntl2ram_a_addr,

    .cntl2ram_w_valid,
    .cntl2ram_w_ready,
    .cntl2ram_w_data,

    .ram2cntl_r_valid,
    .ram2cntl_r_ready,
    .ram2cntl_r_data
  );
endmodule
