`default_nettype none

module mac16x16 (
  input clock,
  input reset_n,

  // Control
  input wire wen, // enable writing to the internal weight buffer
  input wire ren, // enable reading from the internal weight buffer
  input wire sel, // Selects the weight buffer to READ

  // Weight inputs
  input wire [1:0] wbcol, // Column of the 4x4 array two write to
  input wire [4:0] wbidx, // weight index for writing
  input wire [4:0] rbidx, // weight index for reading
  input wire [3:0][3:0][15:0] wb, // weights to write (if enabled)

  // Data inputs
  input wire [3:0][15:0] a, // data
  input wire [3:0][15:0] c, // accumulator

  // Data Output
  output wire [3:0][15:0] x // result
);
  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : ROW
      wire [3:0][15:0] c_tile;
      wire [3:0][15:0] x_tile;

      if (i == 0) begin
        assign c_tile = c;
      end else begin
        assign c_tile = ROW[i-1].x_tile;
      end

      mac4x4 mac (
        .clock,
        .reset_n,

        .sel  (sel),
        .wen  (wen),
        .wbcol(wbcol),
        .wbidx(wbidx),
        .wdata(wdata[i]),
        .ren  (ren),
        .raddr(rbidx),
        .rdata(rb[i]),

        .a(a[i]),
        .c(c_tile),
        .x(x_tile)
      );
    end : ROW
  endgenerate

  assign x = ROW[3].x_tile;
endmodule
