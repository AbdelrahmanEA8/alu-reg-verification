/*-----------------------------------------------------------------------------
 File        : alu_pkt.sv
 Description : ALU transaction classes. alu_pkt_base holds the randomized
               operands (a, b), the opcode, the observed result (acc_out)
               and two control bits: cycle marks two-operand operations (b
               loaded first), and load_b_with_a also asserts load_b on the
               load_a edge (spec F10, about 15 % of packets). alu_pkt adds
               the opcode distribution, weighted operand corners (0000,
               FFFF, AAAA, 5555 at 5 % each, spec 8.2) and the print
               helpers.
-----------------------------------------------------------------------------*/

class alu_pkt_base; 
  rand bit [15:0] a, b;
  rand op_e opcode;
  bit [15:0] acc_out;
  rand bit cycle;
  rand bit load_b_with_a;              // F10: also assert load_b on the load_a edge

  constraint c_both_loads {
    load_b_with_a dist { 1 := 15, 0 := 85 };   // about 15 % of packets
  }

  constraint c1 {
    (opcode==PASSA) -> cycle == '0;
    (opcode!=PASSA) -> cycle == '1;
  }

  //function void printmsg;
  virtual function void printmsg;
    $display("alu_pkt_base: cmd=%h opcode=%h acc_out=%h", {a,b}, opcode, acc_out);
  endfunction

endclass

class alu_pkt extends alu_pkt_base;

  function new();
    super.new();
  endfunction
  
  virtual function void printmsg;
    $display("data1=%h data2=%h opcode=%s acc_out=%h", a, b, opcode.name(), acc_out);
  endfunction

  virtual function string sprint();
    return $sformatf("data1=%h data2=%h opcode=%s acc_out=%h load_b_with_a=%0b",
                     a, b, opcode.name(), acc_out, load_b_with_a);
  endfunction

  constraint c2 {opcode dist {PASSA:=10, NAND:=20, OR:=20, ADD:=50};}

    // Operand corners (spec 8.2): 5 % each for 0000 / FFFF / AAAA / 5555
  constraint c_corners {
    a dist { 16'h0000 := 5, 16'hFFFF := 5, 16'hAAAA := 5, 16'h5555 := 5,
             [16'h0001:16'h5554] :/ 27,
             [16'h5556:16'hAAA9] :/ 26,
             [16'hAAAB:16'hFFFE] :/ 27 };
    b dist { 16'h0000 := 5, 16'hFFFF := 5, 16'hAAAA := 5, 16'h5555 := 5,
             [16'h0001:16'h5554] :/ 27,
             [16'h5556:16'hAAA9] :/ 26,
             [16'hAAAB:16'hFFFE] :/ 27 };
  }
endclass