/*-----------------------------------------------------------------------------
 File        : tb_top.sv
 Description : Testbench top. Instantiates hw_top, builds the ALU
               verification component, connects it to hw_top's interface and
               runs the test.
 Run options : +NUM_PKTS=<n>  number of packets to drive (default 1000).
-----------------------------------------------------------------------------*/

`include "../sv/cycle.sv"
module tb_top;

  import alu_pkg::*;

  // Hardware: DUT, interface and clock generator
  hw_top u_hw_top();

  // VC top level class handle
  alu_vc vc;

  int num_pkts;

  initial begin
    $timeformat(-9, 2, " ns", 8);

    if (!$value$plusargs("NUM_PKTS=%d", num_pkts))
      num_pkts = 1000;

    vc = new("vc", null);
    vc.configure(u_hw_top.u_alu_if);   // VC drives/monitors the DUT's interface
    vc.run(num_pkts);
    $finish;
  end
endmodule
