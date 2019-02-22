`default_nettype none

module SRAM2RW128x32 (
  input  wire [  6:0] A1,
  input  wire [  6:0] A2,
  input  wire         CE1,
  input  wire         CE2,
  input  wire         WEB1,
  input  wire         WEB2,
  input  wire         OEB1,
  input  wire         OEB2,
  input  wire         CSB1,
  input  wire         CSB2,
  input  wire [ 31:0] I1,
  input  wire [ 31:0] I2,
  output reg  [ 31:0] O1,
  output reg  [ 31:0] O2
);
  wire RE1 = ~CSB1 &&  WEB1;
  wire WE1 = ~CSB1 && ~WEB1;
  wire RE2 = ~CSB2 &&  WEB2;
  wire WE2 = ~CSB2 && ~WEB2;

  reg [127:0][31:0] mem;
  reg [31:0] data_out1;
  reg [31:0] data_out2;
  always_ff @(posedge CE) begin
    if (RE1) data_out1 <= mem[A1];
    if (RE2) data_out2 <= mem[A2];
    if (WE1) mem[A1] <= I1;
    if (WE2) mem[A2] <= I2;
  end

  assign O1 = !OEB1 ? data_out1 : 32'bz;
  assign O2 = !OEB2 ? data_out2 : 32'bz;
endmodule
