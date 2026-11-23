/*-----------------------------------------------------------------------------
 File        : vc_test.sv
 Description : Standalone verification component test (module alu_test, no
               DUT). Generates its own clock and alu_if instance and drives
               100 packets to check the VC in isolation, with result
               checking disabled (check_en = 0); stimulus coverage is still
               collected. Not part of the tb/ flow.
-----------------------------------------------------------------------------*/

`include "cycle.sv"
module alu_test;

  // Check import matches your package name`
  import alu_pkg::*;

  bit clk;
  // logic clk = 1'b0;
  // logic reset = 1'b0;

  // 4-Port Switch interface instance
  alu_if intf (clk);

  // Add your VC top level class handle
  alu_vc vc;

  // Clock generator
  initial begin
    clk <= 1'b0;
    forever #(`CYCLE/2) clk <= ~clk;
  end

  initial begin
    $timeformat(-9,2," ns",8);
    // insert your VC instantiation, configuration and run code here:
    vc = new("vc", null);
    vc.configure(intf);
    vc.check_en = 0;      // no DUT: acc_out is never driven, so don't check it
    vc.run(100);
    $finish;
  end
endmodule
   

