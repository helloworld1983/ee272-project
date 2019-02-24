`default_nettype none

module SRAM1RW64x128 (
  input wire [6-1:0] clock,
  input wire CE,
  input wire WEB,
  input wire OEB,
  input wire CSB,
  input wire [128-1:0] I,
  output reg [128-1:0] O
);
  wire RE = ~CSB && WEB;
  wire WE = ~CSB && ~WEB;

  reg [64-1:0][128-1:0] mem;
  reg [128-1:0] data_out;
  always_ff @(posedge CE) begin
    if (RE) data_out <= mem[A];
    if (WE) mem[A] <= I;
  end

  assign O = !OEB ? data_out : 128'bz;
endmodule
