// Wrapper around GCN execution back-end
module execute #(parameter INPUT_W    = 512,
                 parameter INPUT_H    = 128,
                 parameter WEIGHT_W   = 512,
                 parameter WEIGHT_H   = 256,
                 parameter ACTIVATE_W = 256,
                 parameter ACTIVATE_H = 256,
                 parameter OUTPUT_W   = 128,
                 parameter OUTPUT_H   = 256)
(
    input           clock,
    input           reset_n,
    input shortint  in_data     [INPUT_W-1:0][INPUT_H-1:0],
    input shortint  in_weight   [WEIGHT_W-1:0][WEIGHT_H-1:0],
    input shortint  in_activate [ACTIVATE_W-1:0][ACTIVATE_H-1:0],
    input           in_valid,

    output shortint out_data    [OUTPUT_W-1:0][OUTPUT_H-1:0],
    output          out_valid
);

// TODO: add logic

endmodule

