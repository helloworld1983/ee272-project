module tb #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 16,
  parameter BATCH_SIZE = 8
) (
  input wire clock,
  input wire reset_n,

  // Read interface
  input  wire [(ADDR_WIDTH-1):0] rd_addr,
  input  wire                   rd_req,
  output reg                    rd_gnt,
  output reg                    rd_valid,
  output reg [(DATA_WIDTH-1):0] rd_data [0:(BATCH_SIZE-1)],

  // Write interface
  input  wire [(ADDR_WIDTH-1):0] wr_addr,
  input  wire                    wr_req,
  output reg                    wr_gnt,
  input  wire [(DATA_WIDTH-1):0] wr_data [0:(BATCH_SIZE-1)]
);
  //localparam int ADDR_BITS = 32;
  //localparam int DATA_BITS = 32;

  /*
  wire                 cntl2ram_valid;
  wire                 cntl2ram_write;
  wire [ADDR_WIDTH-1:0] cntl2ram_addr;
  wire [DATA_WIDTH-1:0] cntl2ram_wdata;
  wire                 ram2cntl_valid;
  wire [DATA_WIDTH-1:0] ram2cntl_rdata;

  ram #(
    .ADDR_BITS(ADDR_WIDTH),
    .DATA_BITS(DATA_WIDTH)
  ) ram_inst (
    .clock, .reset_n,
    .a_valid(cntl2ram_valid),
    .a_write(cntl2ram_write),
    .a_addr (cntl2ram_addr),
    .a_wdata(cntl2ram_wdata),
    .b_valid(ram2cntl_valid),
    .b_rdata(ram2cntl_rdata)
  );
  */
endmodule
