`default_nettype none

typedef int unsigned uint32_t;
import "DPI-C" context function chandle ram_alloc(uint32_t addr_bits, uint32_t data_bits);
import "DPI-C" function void ram_reset(chandle handle);
import "DPI-C" function void ram_readmemh(chandle handle, string filename);
import "DPI-C" function void ram_write(chandle handle, uint32_t address, uint32_t data);
import "DPI-C" function void ram_read(chandle handle, uint32_t address, output uint32_t data);

// Transaction occurs over two cycles
module ram #(
  parameter string FILENAME  = "", // Filename of initial contents
  parameter int    ADDR_BITS = 16, // Address bits (1-32 supported)
  parameter int    DATA_BITS = 32  // Data bits (only 32 supported)
) (
  input wire clock,
  input wire reset_n,

  // Master signals
  input  wire                 a_valid, // Master request valid
  input  wire                 a_write, // 1 = Write, 0 = Read
  input  wire [ADDR_BITS-1:0] a_addr,  // Address
  input  wire [DATA_BITS-1:0] a_wdata, // Write data

  // Slave signals
  output reg                 b_valid, // 1 when read data is valid
  output reg [DATA_BITS-1:0] b_rdata  // Read data (undefined for writes)
);
  initial begin
    assert(ADDR_BITS > 0 && ADDR_BITS <= 32) else
      $fatal("Invalid ADDR_BITS");
    assert(DATA_BITS == 32) else
      $fatal("Invalid DATA_BITS");
  end

  // C-handle to ram object
  chandle handle;
  initial handle = ram_alloc(ADDR_BITS, DATA_BITS);

  // Widen address so we can use it in a DPI call
  wire [31:0] addr = {{32-ADDR_BITS{1'b0}}, a_addr};

  // Operating state machine
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      ram_reset(handle);
      // If a filename was specified, reset back to the original file contents
      if (FILENAME != "") begin
        ram_readmemh(handle, FILENAME);
      end
      b_valid <= 1'b0;
    end else begin
      b_valid <= 1'b0;
      if (a_valid) begin
        b_valid <= 1'b1;
        if (a_write) begin
          ram_write(handle, addr, a_wdata);
        end else begin
          ram_read(handle, addr, b_rdata);
        end
      end
    end
  end
endmodule
