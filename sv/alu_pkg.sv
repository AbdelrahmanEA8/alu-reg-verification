/*-----------------------------------------------------------------------------
 File        : alu_pkg.sv
 Description : ALU verification package. Defines the opcode type op_e and
               includes the verification component classes: transaction,
               component base, sequencer, driver, monitor, scoreboard,
               coverage, agent and alu_vc.
-----------------------------------------------------------------------------*/

`include "cycle.sv"

package alu_pkg;
  typedef enum bit [1:0] { PASSA, NAND, OR, ADD} op_e;
  
  `include "alu_pkt.sv"
  `include "component_base.sv"
  `include "sequencer.sv"
  `include "driver.sv"
  `include "monitor.sv"
  `include "scoreboard.sv"
  `include "coverage.sv"
  `include "agent.sv"
  `include "alu_vc.sv"

endpackage