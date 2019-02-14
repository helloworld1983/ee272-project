// -------------------------------------------------------------------------------------------------------------------
// General parametrized-port SRAM to hold weights and activations for reads/writes between MAC array and DRAM
//
// Intention is to support, at every given point in time:
//  -- WGT: 1 read-only bank (active with mac), 1 write-only bank (active with dram)
//  -- ACT: 1 read-only bank (active with mac), 1 write-only bank (active with mac), and 1 r/w bank (active with dram)
//
// FIXME: super general and thus may be costly for area. Should explore rewriting to be more specific.
// -------------------------------------------------------------------------------------------------------------------
module globalbuffer #(
  parameter NUM_WGT_RBANK = 1,
  parameter NUM_WGT_WBANK = 1,
  parameter NUM_ACT_RBANK = 2,
  parameter NUM_ACT_WBANK = 1,

  parameter WGT_DEPTH = 256,
  parameter WGT_WIDTH = 256,
  parameter ACT_DEPTH = 256,
  parameter ACT_WIDTH = 256
) (
  input clock,
  input reset_n,

  // Weight array interface
  input  [NUM_WGT_RBANK-1:0][$clog2(WGT_DEPTH)-1:0]                   wgt_raddr,
  input  [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel,
  input  [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_ren,
  output [NUM_WGT_RBANK-1:0][WGT_WIDTH-1:0]                           wgt_rdata,

  input  [NUM_WGT_WBANK-1:0][$clog2(WGT_DEPTH)-1:0]                   wgt_waddr,
  input  [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel,
  input  [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wen,
  input  [NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]                           wgt_wdata,

  // Activation array interface
  input  [NUM_ACT_RBANK-1:0][$clog2(ACT_DEPTH)-1:0]                   act_raddr,
  input  [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel, // FIXME: write assertion to ensure rsel and wsel one-hot
  input  [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_ren,
  output [NUM_ACT_RBANK-1:0][ACT_WIDTH-1:0]                           act_rdata,

  input  [NUM_ACT_WBANK-1:0][$clog2(ACT_DEPTH)-1:0]                   act_waddr,
  input  [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel,
  input  [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wen,
  input  [NUM_ACT_WBANK-1:0][ACT_WIDTH-1:0]                           act_wdata
);


// Trnsform input signals into mask to simplify for loop (FIXME: should flop incoming/outgoing signals)
// -- WGT --
logic [NUM_WGT_RBANK+NUM_WGT_WBANK-1:0][$clog2(WGT_DEPTH)-1:0] wgt_raddr_int, wgt_waddr_int;
logic [NUM_WGT_RBANK+NUM_WGT_WBANK-1:0][WGT_WIDTH-1:0]         wgt_rdata_int, wgt_wdata_int;
logic [NUM_WGT_RBANK+NUM_WGT_WBANK-1:0]                        wgt_rsel_int, wgt_wsel_int;
logic [NUM_WGT_RBANK+NUM_WGT_WBANK-1:0]                        wgt_ren_int, wgt_wen_int;

genvar m;
generate
for (m = 0 ; m < NUM_WGT_RBANK ; m++) begin
  always_comb begin
    wgt_raddr_int = '0;
    wgt_rsel_int = '0;
    wgt_ren_int = '0;
    wgt_rdata_int = '0;

    wgt_raddr_int[wgt_rsel[m]] = wgt_raddr[m];
    wgt_rsel_int[wgt_rsel[m]] = 1'b1;
    wgt_ren_int[wgt_ren[m]] = 1'b1;

    wgt_rdata[m] = wgt_rdata_int[wgt_rsel[m]];
  end
end
endgenerate

genvar n;
generate
for (n = 0 ; n < NUM_WGT_WBANK ; n++) begin
  always_comb begin
    wgt_waddr_int = '0;
    wgt_wsel_int = '0;
    wgt_wen_int = '0;
    wgt_wdata_int = '0;

    wgt_waddr_int[wgt_wsel[n]] = wgt_waddr[n];
    wgt_wsel_int[wgt_wsel[n]] = 1'b1;
    wgt_wen_int[wgt_wen[n]] = 1'b1;

    wgt_wdata_int[wgt_wsel[n]] = wgt_wdata[n];
  end
end
endgenerate

genvar o;
generate
for (o = 0 ; o < (NUM_WGT_RBANK+NUM_WGT_WBANK) ; o++) begin
  floparray #(.DEPTH(WGT_DEPTH),
              .WIDTH(WGT_WIDTH))
  wgt_mem
  (.clock,
   .reset_n,
   .raddr     (wgt_raddr_int[o]),
   .ren       (wgt_ren_int[o] & wgt_rsel_int[o]),
   .rdata     (wgt_rdata_int[o]),
   .waddr     (wgt_waddr_int[o]),
   .wen       (wgt_wen_int[o] & wgt_wsel_int[o]),
   .wdata     (wgt_wdata_int[o])
  );
end
endgenerate


// -- ACT --
logic [NUM_ACT_RBANK+NUM_ACT_WBANK-1:0][$clog2(ACT_DEPTH)-1:0] act_raddr_int, act_waddr_int;
logic [NUM_ACT_RBANK+NUM_ACT_WBANK-1:0][ACT_WIDTH-1:0]         act_rdata_int, act_wdata_int;
logic [NUM_ACT_RBANK+NUM_ACT_WBANK-1:0]                        act_rsel_int, act_wsel_int;
logic [NUM_ACT_RBANK+NUM_ACT_WBANK-1:0]                        act_ren_int, act_wen_int;

genvar j;
generate
for (j = 0 ; j < NUM_ACT_RBANK ; j++) begin
  always_comb begin
    act_raddr_int = '0;
    act_rsel_int = '0;
    act_ren_int = '0;
    act_rdata_int = '0;

    act_raddr_int[act_rsel[j]] = act_raddr[j];
    act_rsel_int[act_rsel[j]] = 1'b1;
    act_ren_int[act_ren[j]] = 1'b1;

    act_rdata[j] = act_rdata_int[act_rsel[j]];
  end
end
endgenerate

genvar k;
generate
for (k = 0 ; k < NUM_ACT_WBANK ; k++) begin
  always_comb begin
    act_waddr_int = '0;
    act_wsel_int = '0;
    act_wen_int = '0;
    act_wdata_int = '0;

    act_waddr_int[act_wsel[k]] = act_waddr[k];
    act_wsel_int[act_wsel[k]] = 1'b1;
    act_wen_int[act_wen[k]] = 1'b1;

    act_wdata_int[act_wsel[k]] = act_wdata[k];
  end
end
endgenerate

genvar l;
generate
for (l = 0 ; l < (NUM_ACT_RBANK+NUM_ACT_WBANK) ; l++) begin
  floparray #(.DEPTH(ACT_DEPTH),
              .WIDTH(ACT_WIDTH))
  act_mem
  (.clock,
   .reset_n,
   .raddr     (act_raddr_int[l]),
   .ren       (act_ren_int[l] & act_rsel_int[l]),
   .rdata     (act_rdata_int[l]),
   .waddr     (act_waddr_int[l]),
   .wen       (act_wen_int[l] & act_wsel_int[l]),
   .wdata     (act_wdata_int[l])
  );
end
endgenerate


endmodule
