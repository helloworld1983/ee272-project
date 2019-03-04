`default_nettype none

`define DATA_WIDTH (128)
`define DEPTH      (512)
`define ADDR_WIDTH ($clog2(`DEPTH))

module KW_ram_1rws_sram_wrap (
  input logic clock,
  input logic reset_n,

  input logic cs_n,
  input logic we_n,

  input  logic [`ADDR_WIDTH-1:0] rw_addr,
  input  logic [`DATA_WIDTH-1:0] data_in,
  output logic [`DATA_WIDTH-1:0] data_out
);
  KW_ram_1rws_sram #(
    .DATA_WIDTH(`DATA_WIDTH),
    .DEPTH(`DEPTH)
  ) dut (
    .clock(clock),
    .reset_n(reset_n),
    .cs_n(cs_n),
    .we_n(we_n),
    .rw_addr(rw_addr),
    .data_in(data_in),
    .data_out(data_out)
  );
endmodule

module KW_ram_1rws_dff_wrap (
  input logic clock,
  input logic reset_n,

  input logic cs_n,
  input logic we_n,

  input  logic [`ADDR_WIDTH-1:0] rw_addr,
  input  logic [`DATA_WIDTH-1:0] data_in,
  output logic [`DATA_WIDTH-1:0] data_out
);
  KW_ram_1rws_dff #(
    .DATA_WIDTH(`DATA_WIDTH),
    .DEPTH(`DEPTH)
  ) dut (
    .clock(clock),
    .reset_n(reset_n),
    .cs_n(cs_n),
    .we_n(we_n),
    .rw_addr(rw_addr),
    .data_in(data_in),
    .data_out(data_out)
  );
endmodule
