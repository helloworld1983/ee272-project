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
  input wire [3:0][3:0][15:0] a, // data
  input wire [3:0][3:0][15:0] c, // accumulator

  // Data Output
  output wire [3:0][3:0][15:0] x // result
);
  // The 16x16 array is decomposed into 16 4x4 mac arrays
  genvar i, j;
  generate
    for (i = 0; i < 4; i = i + 1) begin : ROW
      wire [3:0][3:0][15:0] c_tile;
      wire [3:0][3:0][15:0] x_tile;

      if (i == 0) begin
        assign c_tile = c;
      end else begin
        assign c_tile = ROW[i-1].x_tile;
      end

      for (j = 0; j < 4; j = j + 1) begin : COL
        mac4x4 mac (
          .clock,
          .reset_n,

          .sel  (sel),
          .wen  (wen),
          .ren  (ren),

          .wbcol(wbcol),
          .wbidx(wbidx),
          .wb   (wb[i]),
          .rbidx(rbidx),

          .a(a[i]),
          .c(c_tile[j]),
          .x(x_tile[j])
        );
      end : COL
    end : ROW
  endgenerate

  assign x = ROW[3].x_tile;
endmodule
