/*-----------------------------------------------------------------------------
 File        : alu_if.sv
 Description : ALU interface. Bundles the alu_reg signals and provides two
               clocking blocks: dvr_cb (default) for the driver, which
               drives outputs `Tdrive after the clock edge, and mon_cb for
               the monitor, which samples all signals #1step before the
               edge. Also holds the control (cycle-level) coverage
               (covergroup cg_ctrl on mon_cb and one cover property; spec
               8.1 F1, F3, F4, F10, 8.2, 8.3) and two assertions on acc_out:
               it holds while load_a = 0 (F4) and clears on reset (F1).
-----------------------------------------------------------------------------*/

`include "cycle.sv"

interface alu_if import alu_pkg::*;(
  input logic clk
);
  logic [15:0] acc_out;
  logic [15:0] data;
  op_e         opcode;
  logic        load_a;
  logic        load_b;
  logic        rst_n;

// Clocking block for the interface
default clocking dvr_cb @(posedge clk);
  default input #1step output `Tdrive;
  input acc_out;
  output data, opcode, load_a, load_b, rst_n;
endclocking

clocking mon_cb @(posedge clk);
  default input #1step;
  input data, load_a, load_b, opcode, rst_n, acc_out;
endclocking

// ---------------------------------------------------------------------------
// Control coverage: sampled every clock edge from mon_cb (values just before
// the edge, so no race with the DUT's register updates)
// ---------------------------------------------------------------------------
covergroup cg_ctrl @(mon_cb);
  option.per_instance = 1;

  // Load enables outside reset (F3, F4, F10)
  cp_loads : coverpoint {mon_cb.load_a, mon_cb.load_b} iff (mon_cb.rst_n) {
    bins idle   = {2'b00};
    bins only_b = {2'b01};
    bins only_a = {2'b10};
    bins both   = {2'b11};                 // F10: accum uses the OLD b
  }

  cp_op : coverpoint mon_cb.opcode iff (mon_cb.rst_n);

  // 8.3: opcode x load_a x load_b, for cycles that carry a load
  x_op_loads : cross cp_op, cp_loads {
    ignore_bins idle         = binsof(cp_loads.idle);
    ignore_bins passa_only_b = binsof(cp_op) intersect {PASSA} &&
                               binsof(cp_loads.only_b);
  }

  // Reset edge seen (F1)
  cp_reset : coverpoint mon_cb.rst_n {
    bins reset = {1'b0};
  }

  // Back-to-back loads on consecutive edges (8.2)
  cp_load_a_seq : coverpoint mon_cb.load_a iff (mon_cb.rst_n) {
    bins back_to_back = (1 => 1);
  }
  cp_load_b_seq : coverpoint mon_cb.load_b iff (mon_cb.rst_n) {
    bins back_to_back = (1 => 1);
  }
endgroup

cg_ctrl cg_ctrl_inst = new();

// Multi-cycle scenario (8.2), counted for the end-of-test report
int n_data_chg_no_load;     // data changed while load_a = 0

cov_data_chg_no_load : cover property (@(posedge clk) rst_n && !load_a && $changed(data))
  n_data_chg_no_load++;

function void report_ctrl_coverage();
  $display("  cg_ctrl (control)       %6.2f %%", cg_ctrl_inst.get_inst_coverage());
  $display("    cp_loads              %6.2f %%", cg_ctrl_inst.cp_loads.get_inst_coverage());
  $display("    cp_op                 %6.2f %%", cg_ctrl_inst.cp_op.get_inst_coverage());
  $display("    x_op_loads            %6.2f %%", cg_ctrl_inst.x_op_loads.get_inst_coverage());
  $display("    cp_reset              %6.2f %%", cg_ctrl_inst.cp_reset.get_inst_coverage());
  $display("    cp_load_a_seq         %6.2f %%", cg_ctrl_inst.cp_load_a_seq.get_inst_coverage());
  $display("    cp_load_b_seq         %6.2f %%", cg_ctrl_inst.cp_load_b_seq.get_inst_coverage());
  $display("  cover: data chg, no load   %0d hit(s)", n_data_chg_no_load);
endfunction

// ---------------------------------------------------------------------------
// Assertions: register behavior the scoreboard can't see, because it only
// reads acc_out on the edge after load_a. Disabled when there is no DUT
// (assert_en = 0, set by alu_vc from check_en).
// ---------------------------------------------------------------------------
bit          assert_en = 1;
int n_assert_errors;        // failures, included in the final verdict

// F4: acc_out holds while load_a = 0 (outside reset)
a_acc_hold : assert property (@(posedge clk) disable iff (!assert_en)
                              (rst_n && !load_a) |=> $stable(acc_out))
  else begin
    n_assert_errors++;
    $error("a_acc_hold: acc_out changed from %h to %h without load_a",
           $past(acc_out), acc_out);
  end

// F1: acc_out is 0 after a reset edge
a_acc_reset : assert property (@(posedge clk) disable iff (!assert_en)
                               !rst_n |=> acc_out == '0)
  else begin
    n_assert_errors++;
    $error("a_acc_reset: acc_out = %h after reset, expected 0000", acc_out);
  end

endinterface