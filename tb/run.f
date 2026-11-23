// run.f - ALU testbench compile list (Questa / ModelSim)
// Run from the tb/ folder. Order matters: alu_pkg must be compiled
// before anything that imports it (alu_if, alu_reg, tb_top).

// Include path for alu_pkg's class files and cycle.sv
+incdir+../sv

// Verification component: op_e, packet, sequencer, driver, monitor, agent, alu_vc
../sv/alu_pkg.sv
../sv/alu_if.sv

// DUT and hardware top (alu_reg + alu_if + clkgen)
alu_reg.sv
clk_gen.sv
hw_top.sv

// Testbench top: builds the VC and connects it to hw_top.u_alu_if
tb_top.sv
