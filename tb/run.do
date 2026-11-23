# run.do - compile and run the ALU testbench (Questa / ModelSim)
# Run from the tb/ folder:
#   vsim -c -do run.do     batch: runs, then exits
#   vsim -do run.do        GUI:   runs, then stays open for waves/debug
# Packet count: add +NUM_PKTS=<n> to the vsim line below (default 1000).
# Coverage: saved to alu_cov.ucdb at the end of the run; view the bins with
#   vcover report -details alu_cov.ucdb    (or Coverage > Covergroups in the GUI)

# Create the working library (only the first time, avoids the vlib-34 warning)
if {![file exists work]} { vlib work }

# Compile; -timescale is the default for any file without a `timescale
vlog -timescale 1ns/1ns -f run.f

# Load the testbench; +acc keeps signals and classes visible for waves/debug.
# The seed is printed as "Sv_Seed = N"; rerun a failure with -sv_seed N.
vsim -voptargs="+acc" -sv_seed random work.tb_top

# Save functional coverage (covergroups, cover properties) when the run ends
coverage save -onexit alu_cov.ucdb

# Run to $finish
run -all

# Exit in batch mode only; the GUI stays open
if {[batch_mode]} { quit -f }
