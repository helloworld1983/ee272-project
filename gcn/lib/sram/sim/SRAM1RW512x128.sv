`default_nettype none

module SRAM1RW512x128 (
  input  wire [8:0] A,
  input  wire CE,
  input  wire WEB,
  input  wire OEB,
  input  wire CSB,
  input  wire [127:0] I,
  output reg  [127:0] O
);
  wire RE = ~CSB && WEB;
  wire WE = ~CSB && ~WEB;

  reg [511:0][127:0] mem;
  reg [127:0] data_out;
  always_ff @(posedge CE) begin
    if (RE) data_out <= mem[A];
    if (WE) mem[A] <= I;
  end

  assign O = !OEB ? data_out : 128'bz;
endmodule
