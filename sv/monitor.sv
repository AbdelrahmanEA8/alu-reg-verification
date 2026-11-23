/*-----------------------------------------------------------------------------
 File        : monitor.sv
 Description : ALU monitor. Samples mon_cb on every clock edge and
               reconstructs each transaction per spec section 8.4: records a
               and opcode on load_a, tracks b from load_b (cleared on
               reset), and completes the packet with acc_out on the
               following edge. Reset and idle cycles produce no packets.
               Each packet is printed and sent to every subscriber mailbox
               (scoreboard, coverage); all receive the same read-only
               handle.
-----------------------------------------------------------------------------*/

class monitor extends component_base;
  virtual alu_if vif;
  bit [15:0] b_shadow;   // monitor's copy of the DUT's breg
  bit        pending;    // load_a seen on the previous edge, result due now
  alu_pkt    pend_pkt;   // packet waiting for its acc_out
  mailbox #(alu_pkt) subscribers[$];  // one per consumer, connected by alu_vc

  function new(string name, component_base parent);
    super.new(name, parent);
  endfunction

  task run();
    alu_pkt pkt;
    forever begin
      collect_packet(pkt);
      $display("monitor: @%0t: %s", $time, pkt.sprint());
      // Same handle to every subscriber: safe because a new object is built
      // for each packet and the subscribers only read it
      foreach (subscribers[i]) subscribers[i].put(pkt);
    end
  endtask

  task collect_packet(output alu_pkt pkt);
    pkt = null;
    while (pkt == null) begin
      @(vif.mon_cb);
      // 1. result of last edge's load_a is now on acc_out
      //    (sampled just before this edge, so valid even on a reset edge)
      if (pending) begin
          pend_pkt.acc_out = vif.mon_cb.acc_out;
          pkt     = pend_pkt;
          pending = 0;
      end
      // 2. reset edge: breg clears
      if (!vif.mon_cb.rst_n) begin
          b_shadow = '0;
          continue;
      end
      // 3. load_a: capture a/opcode with the OLD b
      if (vif.mon_cb.load_a) begin
          pend_pkt        = new();
          pend_pkt.a      = vif.mon_cb.data;
          pend_pkt.opcode = vif.mon_cb.opcode;
          pend_pkt.b      = b_shadow;
          pend_pkt.load_b_with_a = vif.mon_cb.load_b;   // observed F10 (both loads)
          pending = 1;
      end
      // 4. load_b: update the copy AFTER the pending completion
      if (vif.mon_cb.load_b)
          b_shadow = vif.mon_cb.data;
    end
  endtask
endclass
