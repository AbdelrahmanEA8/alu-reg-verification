/*-----------------------------------------------------------------------------
 File        : alu_vc.sv
 Description : ALU verification component (top-level class). Contains the
               agent, the scoreboard and the coverage collector; the monitor
               feeds both through one mailbox each. configure() connects the
               components to a virtual alu_if; run(n) drives n packets while
               the monitor, scoreboard and coverage run in the background,
               then prints the scoreboard report (including the interface
               assertion failures) and the coverage report. Set check_en = 0
               to run without a DUT: result checking and assertions are off.
-----------------------------------------------------------------------------*/

class alu_vc extends component_base;
  agent              agnt;
  scoreboard         sb;
  alu_coverage       cov;
  mailbox #(alu_pkt) mon2sb;        // monitor -> scoreboard
  mailbox #(alu_pkt) mon2cov;       // monitor -> coverage
  bit                check_en = 1;  // 0: standalone run without a DUT
  virtual alu_if     vif;

  function new(string name, component_base parent);
    super.new(name, parent);
    agnt    = new("agnt", this);
    sb      = new("sb", this);
    cov     = new("cov", this);
    mon2sb  = new();                // unbounded: put() never blocks
    mon2cov = new();
    sb.mon2sb   = mon2sb;
    cov.mon2cov = mon2cov;
  endfunction

  // Subscribe the consumers to the monitor (called once check_en is final)
  function void connect();
    agnt.mon.subscribers.delete();
    if (check_en) agnt.mon.subscribers.push_back(mon2sb);
    agnt.mon.subscribers.push_back(mon2cov);
  endfunction

  task run(input int runs);
    connect();
    vif.assert_en = check_en;                 // no DUT: acc_out undriven, skip assertions
    fork
      agnt.mon.run();
      cov.run();
      if (check_en) sb.run();
    join_none
    agnt.dvr.run(runs);                       // returns after the drain
    if (check_en) sb.report(runs, vif.n_assert_errors);
    cov.report();
  endtask

  function void configure(virtual alu_if vif);
    this.vif     = vif;
    agnt.dvr.vif = vif;
    agnt.mon.vif = vif;
    cov.vif      = vif;
  endfunction
endclass