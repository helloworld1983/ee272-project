// Compute AxB + C over N cycles
// We can express the matrix multiply as follows
//
// for i = 0:I
//   for j = 0:J
//     for k = 0:K
//       R[i,j] = A[i,k] * B[k,j] + C[i,j]
//
// In this case, all B[k, j] values are stored in registers and on clock cycle c we recive
// [A[c, 0], ..., A[c, K-1]] and compute [R[c, 0], ..., R[c, J-1]]
module mac4x4 (
  input clock,
  input reset_n,

  // Control
  input en, // enable operation

  // data IO
  input  [3:0][15:0] a,    // input data
  input       [ 4:0] bidx, // weight index
  input  [3:0][15:0] c,    // accumulator input

  output             r_v, // Is result data valid
  output [3:0][15:0] r    // result data
);
  // State machine
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      r_v <= 1'b0;
    end else begin
      r_v <= en;
    end
  end

  // Compute
  reg b[3:0][3:0][31:0];
  genvar j;
  generate
    for (j = 0; j < 4; j = j + 1) begin
      always_ff @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
          r[j] <= 'd0;
        end else if(en) begin
          // R_ij = SUM(aik * bkj
          r[j] <= a[0] * b[0][j][bidx]
                + a[1] * b[1][j][bidx]
                + a[2] * b[2][j][bidx]
                + a[3] * b[3][j][bidx]
                + c[j];
        end
      end
    end
  endgenerate
endmodule
