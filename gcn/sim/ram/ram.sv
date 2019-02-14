`default_nettype none

typedef int unsigned uint32_t;
import "DPI-C" context function chandle ram_alloc(uint32_t addr_bits, uint32_t data_bits);
import "DPI-C" function void ram_reset(chandle handle);
import "DPI-C" function void ram_readmemh(chandle handle, string filename);
import "DPI-C" function void ram_write(chandle handle, uint32_t address, uint32_t data);
import "DPI-C" function void ram_read(chandle handle, uint32_t address, output uint32_t data);

// Transaction occurs over two cycles for writes, 3 cycles for reads
module ram #(
  parameter string FILENAME  = "", // Filename of initial contents
  parameter int    ADDR_BITS = 32, // Address bits (1-32 supported)
  parameter int    DATA_BITS = 32  // Data bits (only 32 supported)
) (
  input wire clock,
  input wire reset_n,

  // Master address channel
  input  wire                 a_valid, // Master request valid
  output reg                  a_ready, // Slave ready
  input  wire                 a_write, // 1 = Write, 0 = Read
  input  wire [ADDR_BITS-1:0] a_addr,  // Address

  // Master write data channel
  input  wire                 w_valid, // Master data valid
  output reg                  w_ready, // Slave ready
  input  wire [DATA_BITS-1:0] w_data,  // Write data

  // Slave read data channel
  output reg                  r_valid, // Slave data valid
  input  wire                 r_ready, // Master data ready
  output reg  [DATA_BITS-1:0] r_data   // Read data
);
  initial begin
    assert(ADDR_BITS > 0 && ADDR_BITS <= 32) else
      $fatal("Invalid ADDR_BITS");
    assert(DATA_BITS == 32) else
      $fatal("Invalid DATA_BITS");
  end

  typedef enum bit [1:0] { STATE_IDLE, STATE_WRITE, STATE_READ, STATE_READ_RESP } state_t;

  // C-handle to ram object
  chandle handle;
  initial handle = ram_alloc(ADDR_BITS, DATA_BITS);

  // State machine
  state_t state;
  reg [31:0] addr;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      addr  <= 32'd0;
      state <= STATE_IDLE;
      // If a filename was specified, reset back to the original file contents
      ram_reset(handle);
      if (FILENAME != "") begin
        ram_readmemh(handle, FILENAME);
      end
    end else case (state)
      STATE_IDLE:
        if (a_valid && a_ready) begin
          addr  <= {{32-ADDR_BITS{1'b0}}, a_addr};
          state <= (a_write ? STATE_WRITE : STATE_READ);
        end
      STATE_WRITE:
        if (w_valid && w_ready) begin
          ram_write(handle, addr, w_data);
          state <= STATE_IDLE;
        end
      STATE_READ:
        begin
          ram_read(handle, addr, r_data);
          state <= STATE_READ_RESP;
        end
      STATE_READ_RESP:
        if (r_valid && r_ready) begin
          state <= STATE_IDLE;
        end
    endcase
  end
  assign a_ready = (state == STATE_IDLE);
  assign w_ready = (state == STATE_WRITE);
  assign r_valid = (state == STATE_READ_RESP);
endmodule
