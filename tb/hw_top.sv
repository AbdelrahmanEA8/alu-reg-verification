/*-----------------------------------------------------------------------------
 File        : hw_top.sv
 Description : Hardware top. Instantiates the DUT (alu_reg), the ALU
               interface and the clock generator, and connects the DUT ports
               to the interface signals (spec Fig. 3).
-----------------------------------------------------------------------------*/

`include "../sv/cycle.sv"

module hw_top();
  // Clock signal for the ALU and interface
  logic        clk;

  // ALU Register Instance
  alu_reg u_alu_reg (
    .acc_out(u_alu_if.acc_out),
    .data(u_alu_if.data),
    .opcode(u_alu_if.opcode),
    .load_a(u_alu_if.load_a),
    .load_b(u_alu_if.load_b),
    .clk(clk),
    .rst_n(u_alu_if.rst_n)
  );

  // ALU Interface Instance
  alu_if u_alu_if (clk);

  // Clock Generator Instance
  clkgen u_clkgen (
    .clk(clk)
  );

endmodule