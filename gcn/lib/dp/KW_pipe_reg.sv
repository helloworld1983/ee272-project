`default_nettype none

// Simple pipeline register with DEPTH logic stages
module KW_pipe_reg #(
  parameter int DATA_WIDTH,
  parameter int DEPTH
) (
  input logic clock,
  input logic reset_n,

  input  logic [DATA_WIDTH-1:0] a,
  output logic [DATA_WIDTH-1:0] b
);

  genvar i;
  generate
    for (i = 0; i < DEPTH; i = i + 1) begin : PIPELINE
      logic [DATA_WIDTH-1:0] pipe;
      if (i == 0) begin
        always_ff @(posedge clock or negedge reset_n) begin
          if (~reset_n) begin
            pipe <= {DATA_WIDTH{1'b0}};
          end else begin
            pipe <= a;
          end
        end
      end else begin
        always_ff @(posedge clock or negedge reset_n) begin
          if (~reset_n) begin
            pipe <= {DATA_WIDTH{1'b0}};
          end else begin
            pipe <= PIPELINE[i-1].pipe;
          end
        end
      end
    end : PIPELINE
  endgenerate

  assign b = PIPELINE[DEPTH-1].pipe;
endmodule
