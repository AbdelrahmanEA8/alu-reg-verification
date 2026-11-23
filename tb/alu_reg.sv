/*-----------------------------------------------------------------------------
 File        : alu_reg.sv
 Description : DUT: 16-bit ALU register. Register b loads data when load_b
               is set; when load_a is set, acc_out captures the result of
               opcode applied to data and b (PASSA, NAND, OR, ADD).
               Synchronous active-low reset clears b and acc_out.
-----------------------------------------------------------------------------*/

`include "../sv/cycle.sv"

module alu_reg import alu_pkg::*;(
  output logic [15:0] acc_out,
  input logic [15:0] data,
  input op_e opcode,
  input logic load_a, load_b,
  input logic clk, rst_n
);

logic [15:0] b, alu;

always_ff @(posedge clk) begin
  if (!rst_n) b <= '0;
  else if (load_b) b <= data;
end

always_comb begin
  case (opcode)
    PASSA: alu = data;
    NAND : alu = ~(data & b);
    OR : alu = data | b;
    ADD : alu = data + b;
  endcase
end

always_ff @(posedge clk) begin
  if (!rst_n) acc_out <= '0;
  else if (load_a) acc_out <= alu;
end
endmodule