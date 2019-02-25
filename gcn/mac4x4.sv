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

  /* Double buffer control */
  input logic swap_n,

  /* Memory write control */
  // enable writing to the internal weight buffer. Active low.
  input logic w_en_n,

  // Weight inputs
  input logic [ 1:0] w_col, // Column of the 4x4 array two write to
  input logic [ 4:0] w_addr, // weight index for writing
  input logic [3:0][15:0] w_data, // weights to write (if enabled)

  /* MAC Control */
  input logic r_en_n, // Read from the internal weight buffer and compute a MAC. Active low.
  input logic [4:0] r_addr, // Weight index for reading

  /* MAC datapath */
  input  logic [3:0][15:0] a, // Data
  input  logic [3:0][15:0] c, // Accumulator
  output logic [3:0][15:0] x  // Result
);
  genvar j;
  generate
    for (j = 0; j < 4; j = j + 1) begin : SLICE
      // Compute which slice should be written to
      wire w_en_slice_n = (w_col == j) ? w_en_n : 1'b1;

      wire [3:0][15:0] r_data;
      KW_dblbuf #(
        .DATA_WIDTH(4 * 16),
        .DEPTH(32)
      ) buffer (
        .clock(clock),
        .reset_n(reset_n),
        .swap_n(swap_n),
        .w_en_n(w_en_slice_n),
        .w_addr(w_addr),
        .w_data(w_data),
        .r_en_n(r_en_n),
        .r_addr(r_addr),
        .r_data(r_data)
      );

      mac4x4_slice mac (
        .clock(clock),
        .reset_n(reset_n),
        .a(a),
        .b(r_data),
        .c(c[j]),
        .x(x[j])
      );
    end : SLICE
  endgenerate
endmodule

module mac4x4_slice (
  input logic clock,
  input logic reset_n,

  // Data input
  input logic [3:0][15:0] a,
  input logic [3:0][15:0] b,
  input logic      [15:0] c,

  // Data output
  output logic [15:0] x
);
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      x <= 'd0;
    end else begin
      x <= a[0] * b[0]
         + a[1] * b[1]
         + a[2] * b[2]
         + a[3] * b[3]
         + c;
    end
  end
endmodule
