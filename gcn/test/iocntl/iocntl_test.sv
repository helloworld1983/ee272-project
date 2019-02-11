module tb (
  input wire clock,
  input wire reset_n,

  // Read interface
  input  wire [27:0] rd_addr,
  input  wire        rd_req,
  output reg         rd_gnt,
  output reg         rd_valid,
  output reg [15:0]  rd_data [0:7],

  // Write interface
  input  wire [25:0] wr_addr,
  input  wire        wr_req,
  output reg         wr_gnt,
  input  wire [15:0] wr_data [0:7]
);
  localparam int ADDR_BITS = 32;
  localparam int DATA_BITS = 32;

  wire                 cntl2ram_valid;
  wire                 cntl2ram_write;
  wire [ADDR_BITS-1:0] cntl2ram_addr;
  wire [DATA_BITS-1:0] cntl2ram_wdata;
  wire                 ram2cntl_valid;
  wire [DATA_BITS-1:0] ram2cntl_rdata;

  ram #(
    .ADDR_BITS(ADDR_BITS),
    .DATA_BITS(DATA_BITS)
  ) ram_inst (
    .clock, .reset_n,
    .a_valid(cntl2ram_valid),
    .a_write(cntl2ram_write),
    .a_addr (cntl2ram_addr),
    .a_wdata(cntl2ram_wdata),
    .b_valid(ram2cntl_valid),
    .b_rdata(ram2cntl_rdata)
  );
endmodule
