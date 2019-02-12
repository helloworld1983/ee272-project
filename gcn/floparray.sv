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
logic ren_q, wen_q;
logic [$clog2(DEPTH)-1:0] raddr_q, waddr_q;
logic [WIDTH-1:0] wdata_q;

always_ff @ (posedge clock) begin
    if (~reset_n) begin
        raddr_q <= '0;
        ren_q   <= 1'b0;
        waddr_q <= '0;
        wen_q   <= 1'b0;
    end
    else begin
        raddr_q <= raddr;
        ren_q   <= ren;
        waddr_q <= waddr;
        wen_q   <= wen;

        rdata <= ren_q ? mem[raddr_q] : 0;
        mem[waddr_q] <= (wen_q & ~ren_q) ? wdata_q : mem[waddr_q]; // Or waddr != raddr
    end
end



endmodule
