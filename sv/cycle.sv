/*-----------------------------------------------------------------------------
 File        : cycle.sv
 Description : Global timing definitions included by every design element:
               clock period `CYCLE (default 10 ns, overridable with
               +define+CYCLE=<n>), driver output skew `Tdrive (20% of the
               period) and `timescale 1ns/1ns.
-----------------------------------------------------------------------------*/

`ifndef CYCLE
  `define CYCLE 10
`endif

`ifndef Tdrive
  `define Tdrive #(0.2*`CYCLE)
`endif

`timescale 1ns/1ns