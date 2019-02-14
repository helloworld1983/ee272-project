// -------------------------------------------------------------------------------------------------------------------
// Combinational logic to select the global buffer's banks based on swap signal from dram2gb_cntl FSM.
// -------------------------------------------------------------------------------------------------------------------
module swaparbitrator #(
  parameter NUM_WGT_RBANK = 1,
  parameter NUM_WGT_WBANK = 1,
  parameter NUM_ACT_RBANK = 2,
  parameter NUM_ACT_WBANK = 1
) (
  input clock,
  input reset_n,

  input logic swap,

  output logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel,
  output logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel,
  output logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel,
  output logic [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel
);

// --- INITIAL VALUES
logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel_init;
logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel_init;
logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel_init;
logic [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel_init;

genvar a, b, c, d;
generate
  for (a = 0 ; a < NUM_WGT_RBANK ; a++) begin
    always_comb begin
      wgt_rsel_init[a] = a;
    end
  end
  for (b = 0 ; b < NUM_WGT_WBANK ; b++) begin
    always_comb begin
      wgt_wsel_init[b] = b+NUM_WGT_RBANK;
    end
  end
  for (c = 0 ; c < NUM_ACT_RBANK ; c++) begin
    always_comb begin
      act_rsel_init[c] = c;
    end
  end
  for (d = 0 ; d < NUM_ACT_WBANK ; d++) begin
    always_comb begin
      act_wsel_init[d] = d+NUM_ACT_RBANK;
    end
  end
endgenerate


// --- NEXT VALUES: FIXME can likely create more efficient logic than ADDERS.
logic [NUM_WGT_RBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_rsel_next;
logic [NUM_WGT_WBANK-1:0][$clog2(NUM_WGT_RBANK+NUM_WGT_WBANK)-1:0] wgt_wsel_next;
logic [NUM_ACT_RBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_rsel_next;
logic [NUM_ACT_WBANK-1:0][$clog2(NUM_ACT_RBANK+NUM_ACT_WBANK)-1:0] act_wsel_next;

genvar m, n, j, k;
generate
  for (m = 0 ; m < NUM_WGT_RBANK ; m++) begin
    always_comb begin
      wgt_rsel_next[m] = (|wgt_rsel[m]) ? '0 : wgt_rsel[m];
    end
  end
  for (n = 0 ; n < NUM_WGT_WBANK ; n++) begin
    always_comb begin
      wgt_wsel_next[n] = (|wgt_wsel[n]) ? '0 : wgt_wsel[n];
    end
  end
  for (j = 0 ; j < NUM_ACT_RBANK ; j++) begin
    always_comb begin
      act_rsel_next[j] = (|act_rsel[j]) ? '0 : act_rsel[j];
    end
  end
  for (k = 0 ; k < NUM_ACT_WBANK ; k++) begin
    always_comb begin
      act_wsel_next[k] = (|act_wsel[k]) ? '0 : act_wsel[k];
    end
  end
endgenerate

// --- OUTPUT VALUES
always_ff @ (posedge clock) begin
  if (~reset_n) begin
    wgt_rsel <= wgt_rsel_init;
    wgt_wsel <= wgt_wsel_init;
    act_rsel <= act_rsel_init;
    act_wsel <= act_wsel_init;
  end
  else begin
    if (swap) begin
      wgt_rsel <= wgt_rsel_next;
      wgt_wsel <= wgt_wsel_next;
      act_rsel <= act_rsel_next;
      act_wsel <= act_wsel_next;
    end
  end
end

endmodule // swaparbitrator.sv
