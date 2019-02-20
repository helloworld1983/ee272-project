`default_nettype none

module reductionbuffer (
  input  wire clock,
  input  wire reset_n,

  // Control interface
  input  wire sel, // Selects the accumulator buffer to READ

  // Write interface
  input  wire              wen,   // Enable writing to the activation buffer
  input  wire [15:0][15:0] wdata, // Data input from the MAC array

  // Read interface
  input  wire              ren,   // Enable reading from the activation buffer
  input  wire       [ 7:0] ridx,  // Which of the 256 rows to read from
  output reg  [15:0][15:0] rdata  // The resulting activations
);
  // main memory for the reduction values
  reg [15:0][15:0][15:0] memory [0:1];
  reg       [15:0][15:0] wbuff;

  reg [7:0] widx_ff;
  always_ff @(posedge clock or negedge reset_n) begin
    if (~reset_n) begin
      widx_ff <= 8'b0;
      memory  <= '{0, 0};
    end else begin
      if (wen) begin
        // TODO: This is very hacky... we'll need to revisit for synthesis
        memory[~sel][widx_ff] <= wdata + memory[~sel][widx_ff];
        widx_ff <= widx_ff + 'b1;
      end
      if (ren) begin
        rdata <= memory[sel][ridx];
      end
    end
  end
endmodule