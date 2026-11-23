/*-----------------------------------------------------------------------------
 File        : coverage.sv
 Description : ALU functional coverage collector (transaction level).
               Receives each completed transaction from the monitor through
               a mailbox and samples cg_pkt: opcodes, corner and range bins
               of operands a and b, opcode x operand crosses, and ADD with
               and without overflow (spec 8.1 F5-F9, 8.2, 8.3). report()
               prints this covergroup and the interface's control coverage.
-----------------------------------------------------------------------------*/

class alu_coverage extends component_base;
  mailbox #(alu_pkt) mon2cov;    // from the monitor, connected by alu_vc
  virtual alu_if     vif;        // for the control coverage report
  int n_sampled;


  covergroup cg_pkt with function sample(alu_pkt p);
  // instead of creating a separete sample() task, we can use the covergroup's sample() function directly
    option.per_instance = 1;

    cp_op : coverpoint p.opcode;                        // F5-F8

    cp_a : coverpoint p.a {                             // 8.2 operand corners
      bins zero   = {16'h0000};
      bins ones   = {16'hFFFF};
      bins h_aaaa = {16'hAAAA};
      bins h_5555 = {16'h5555};
      bins low    = {[16'h0001:16'h5554]};
      bins mid    = {[16'h5556:16'hAAA9]};
      bins high   = {[16'hAAAB:16'hFFFE]};
    }

    cp_b : coverpoint p.b {
      bins zero   = {16'h0000};
      bins ones   = {16'hFFFF};
      bins h_aaaa = {16'hAAAA};
      bins h_5555 = {16'h5555};
      bins low    = {[16'h0001:16'h5554]};
      bins mid    = {[16'h5556:16'hAAA9]};
      bins high   = {[16'hAAAB:16'hFFFE]};
    }

    x_op_a : cross cp_op, cp_a;                         // every opcode x every a bin
    x_op_b : cross cp_op, cp_b;                         // 8.2: b = 0 / FFFF with every opcode

    // ADD: the 17-bit sum shows the carry-out (F9, 8.3 overflow)
    cp_add_carry : coverpoint ({1'b0, p.a} + {1'b0, p.b}) iff (p.opcode == ADD) {
      bins no_carry = {[17'h00000:17'h0FFFF]};
      bins carry    = {[17'h10000:17'h1FFFE]};        // overflow occurred (F9, 8.3)
    }
  endgroup

  function new(string name, component_base parent);
    super.new(name, parent);
    cg_pkt = new();
  endfunction

  task run();
    alu_pkt pkt;
    forever begin
      mon2cov.get(pkt);                   // shared handle: read only
      cg_pkt.sample(pkt);
      n_sampled++;
    end
  endtask

  function void report();
    $display("===============================");
    $display("Coverage report: %0d transactions sampled", n_sampled);
    $display("  cg_pkt (transactions)   %6.2f %%", cg_pkt.get_inst_coverage());
    $display("    cp_op                 %6.2f %%", cg_pkt.cp_op.get_inst_coverage());
    $display("    cp_a                  %6.2f %%", cg_pkt.cp_a.get_inst_coverage());
    $display("    cp_b                  %6.2f %%", cg_pkt.cp_b.get_inst_coverage());
    $display("    x_op_a                %6.2f %%", cg_pkt.x_op_a.get_inst_coverage());
    $display("    x_op_b                %6.2f %%", cg_pkt.x_op_b.get_inst_coverage());
    $display("    cp_add_carry          %6.2f %%", cg_pkt.cp_add_carry.get_inst_coverage());
    if (vif != null) vif.report_ctrl_coverage();
    $display("  Bin details: vcover report -details alu_cov.ucdb");
    $display("===============================");
  endfunction
endclass
