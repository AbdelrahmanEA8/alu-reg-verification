/*-----------------------------------------------------------------------------
 File        : driver.sv
 Description : ALU driver. Pulls packets from the sequencer and drives them
               through dvr_cb: two-operand operations load b, then a on the
               next cycle; PASSA loads a only. When load_b_with_a is set,
               load_b is also asserted on the load_a edge (spec F10). Holds
               reset until the first clock edge, releases the load enables
               after the last packet, and reports the number of packets
               driven.
-----------------------------------------------------------------------------*/

class driver extends component_base;
  sequencer sref;
  alu_pkt pkt;
  virtual alu_if vif;

  function new(string name, component_base parent);
      super.new(name, parent);
  endfunction
  /* as we work with pull technique so the driver component should handle
     the number of packets generated. it will be passed from the vc
  */
  task run(input int runs);
    initialize(); // To avoid 0-time race conditions
    repeat(runs) begin
      sref.get_next_item(pkt);
      $display("driver: @%0t: %s", $time, pkt.sprint());
      drive_packet(pkt);
    end
    finish(); // drop the load enables so the DUT stops recapturing
    report(runs);
  endtask

  task drive_packet(input alu_pkt pkt);
    if (pkt.cycle) begin            // two-operand op: load b first
      @(vif.dvr_cb);
      vif.dvr_cb.data   <= pkt.b;
      vif.dvr_cb.load_b <= 1'b1;
      vif.dvr_cb.load_a <= 1'b0;
      vif.dvr_cb.opcode <= pkt.opcode;
      vif.dvr_cb.rst_n <= 1'b1;
    end
    @(vif.dvr_cb);                      // present a, capture result
    vif.dvr_cb.data   <= pkt.a;
    vif.dvr_cb.load_a <= 1'b1;
    vif.dvr_cb.load_b <= pkt.load_b_with_a;  // F10: also assert load_b on the load_a edge
    vif.dvr_cb.opcode <= pkt.opcode;    // explicit, instead of relying on hold
    vif.dvr_cb.rst_n <= 1'b1;
  endtask

  task initialize();  // Drive without using the Clocking block timing control
    vif.data <= '0;
    vif.opcode <= PASSA;
    vif.load_a <= '0;
    vif.load_b <= '0;
    vif.rst_n <= '0;
  endtask

  task finish();
    // VC-22: drop the load enables so the DUT stops recapturing,
    // then let the last result reach acc_out for the monitor
    @(vif.dvr_cb);
    vif.dvr_cb.load_a <= 1'b0;
    vif.dvr_cb.load_b <= 1'b0;
    repeat (2) @(vif.dvr_cb);
  endtask

  task report(int runs);
    $display("===============================");
    $display("Driver report: %0d packets have been processed", runs);
    $display("===============================");
  endtask
endclass