`default_nettype none

// Compute AxB + C over N cycles
module mac16x16 (
  input logic clock,
  input logic reset_n,

  /* Double buffer control */
  input logic swap_n,

  /* Weight write interface */
  input logic w_en_n, // Write to the internal weight buffer. Active low.
  input logic [3:0] w_col, // Column of the 16x16 array to write
  input logic [4:0] w_addr, // weight index for writing
  input logic [3:0][3:0][15:0] w_data, // weights to write (if enabled)

  /* MAC Control */
  input logic r_en_n, // Read from the internal weight buffer and compute a MAC. Active low.
  input logic [4:0] r_addr, // Weight index for reading

  /* MAC datapath */
  input  logic [3:0][3:0][15:0] a, // Data
  input  logic [3:0][3:0][15:0] c, // Accumulator
  output logic [3:0][3:0][15:0] x  // Result
);
  // For now, all tiles get data input at the same time
  wire [3:0][3:0][15:0] a_tile;
  assign a_tile = a;

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
        // Decode which column is being written to
        wire w_en_tile_n = (j == w_col[3:2]) ? w_en_n : 1'b1;
        mac4x4 mac (
          .clock  (clock),
          .reset_n(reset_n),
          .swap_n (swap_n),

          .w_en_n (w_en_tile_n),
          .w_col  (w_col[1:0]),
          .w_addr (w_addr),
          .w_data (w_data[i]),

          .r_en_n (r_en_n),
          .r_addr (r_addr),

          .a(a_tile[i]),
          .c(c_tile[j]),
          .x(x_tile[j])
        );
      end : COL
    end : ROW
  endgenerate

  assign x = ROW[3].x_tile;
endmodule
