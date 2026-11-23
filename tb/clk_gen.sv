/*-----------------------------------------------------------------------------
 File        : clk_gen.sv
 Description : Clock generator (module clkgen). Produces the free-running
               clock shared by the DUT and the testbench; the period is
               `CYCLE from cycle.sv.
-----------------------------------------------------------------------------*/

`include "../sv/cycle.sv"

module clkgen (output logic clk);
  initial begin
    clk <= '0; // NBA to avoid 0 simulation time Race
    forever #(`CYCLE/2) clk = ~clk;
  end
endmodule