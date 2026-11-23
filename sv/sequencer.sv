/*-----------------------------------------------------------------------------
 File        : sequencer.sv
 Description : ALU sequencer. Returns a new randomized alu_pkt each time the
               driver calls get_next_item().
-----------------------------------------------------------------------------*/

class sequencer extends component_base;
  alu_pkt s_pkt;

  function new(string name, component_base parent);
    super.new(name, parent);
  endfunction

  function void get_next_item(output alu_pkt pkt);
    s_pkt = new();
    if (!s_pkt.randomize()) begin
      $error("[%0t] %s: Randomization failed for packet!", $time, getname());
    end
    pkt = s_pkt;
  endfunction

endclass