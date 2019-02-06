`default_nettype none
// Compute AxB + C over N cycles
// We can express the matrix multiply as follows
//
// for i = 0:I
//   for j = 0:J
//     for k = 0:K
//       X[i,j] = A[i,k] * B[k,j] + C[i,j]
//
// In this case, all B[k, j] values are stored in registers and on clock cycle c we recive
// [A[c, 0], ..., A[c, K-1]] and compute [X[c, 0], ..., X[c, J-1]]
module mac4x4 (
  input wire clock,
  input wire reset_n,

  // Control
  input wire wen, // enable writing to the internal weight buffer
  input wire ren, // enable reading from the internal weight buffer
  input wire sel, // Selects the weight buffer to READ

  // Weight inputs
  input wire [1:0]       wbcol, // Column of the 4x4 array two write to
  input wire [4:0]       wbidx, // weight index for writing
  input wire [4:0]       rbidx, // weight index for reading
  input wire [3:0][15:0] wb,    // weights to write (if enabled)

  // Data inputs
  input wire [3:0][15:0] a, // data
  input wire [3:0][15:0] c, // accumulator

  // Data Output
  output wire [3:0][15:0] x // result
);
  genvar j;
  generate
    for (j = 0; j < 4; j = j + 1) begin : SLICE
      // Compute which slice should be written to
      wire wen_slice = wen && (wbcol == j);

      wire [3:0][15:0] rb;
      mac4x4_buffer buffer (
        .clock,
        .reset_n,
        .sel  (sel),
        .wen  (wen_slice),
        .waddr(wbidx),
        .wdata(wb),
        .ren  (ren),
        .raddr(rbidx),
        .rdata(rb)
      );

      mac4x4_slice mac (
        .clock,
        .reset_n,
        .a(a),
        .b(rb),
        .c(c[j]),
        .x(x[j])
      );
    end : SLICE
  endgenerate
endmodule

module mac4x4_buffer (
  input wire clock,
  input wire reset_n,

  // Control
  input wire sel, // Select the buffer to READ FROM

  // Write interface
  input wire             wen,   // Write enable
  input wire [4:0]       waddr, // Write address
  input wire [3:0][15:0] wdata,

  // Read interface
  input  wire             ren,   // Read enable
  input  wire [4:0]       raddr, // Read address
  output reg  [3:0][15:0] rdata
);
  // Read/Write data
  reg [31:0][3:0][15:0] data [0:1];
  always_ff @(posedge clock) begin
    if (ren) rdata <= data[sel][raddr];
    if (wen) data[!sel][waddr] <= wdata;
  end
endmodule

module mac4x4_slice (
  input wire clock,
  input wire reset_n,

  // Data input
  input wire [3:0][15:0] a,
  input wire [3:0][15:0] b,
  input wire      [15:0] c,

  // Data output
  output reg [15:0] x
);
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      x <= 'd0;
    end else begin
      x <= a[0] * b[0] + a[1] * b[1]
         + a[2] * b[2] + a[3] * b[3]
         + c;
    end
  end
endmodule
