// Generalized buffer interface
module floparray #(
    parameter DEPTH = 32,
    parameter WIDTH = 256
) (
  input  clock,
  input  reset_n,

  input  logic [$clog2(DEPTH)-1:0] raddr,
  input  logic             ren,
  output logic [WIDTH-1:0] rdata, // Available one cycle later

  input  logic [$clog2(DEPTH)-1:0] waddr,
  input  logic             wen,
  input  logic [WIDTH-1:0] wdata
);
  logic [$clog2(DEPTH)-1:0][WIDTH-1:0] mem;
  always_ff @ (posedge clock) begin
    if (~reset_n) begin
      rdata <= 'b0;
    end else begin
      rdata <= ren ? mem[raddr] : 'b0;
      if (wen & ~ren)
        mem[waddr_q] <= wdata;
    end
  end
endmodule
