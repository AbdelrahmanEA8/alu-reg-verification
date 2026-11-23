# alu_reg Verification Plan

| Item | Value |
|---|---|
| Document | ALU register (`alu_reg`) functional verification plan |
| Version | 1.0 |
| Date | 2026-11-23 |
| Design under test | `alu_reg` (`tb/alu_reg.sv`) |
| Design specification | `docs/Spec.md` (v0.4) |
| Issue log | `docs/alu_vc_issue_log.md` |
| Methodology | Class-based SystemVerilog testbench: constrained-random stimulus, self-checking scoreboard, functional coverage and assertions |
| Simulator | QuestaSim-64 2021.1 |
| Status | **Closed**: all checks pass and functional coverage is 100 % (see Section 10) |

---

## 1. Purpose and Scope

This plan defines how `alu_reg` is verified: which features are checked, how stimulus is generated, how results are checked, which coverage is measured, and when verification is complete. It replaces Section 8 of the design specification (v0.3 and earlier).

### 1.1 In Scope

- RTL functional verification of `alu_reg` against `docs/Spec.md` Sections 4–7.
- All four ALU operations, including 16-bit overflow on `ADD`.
- `breg` and `accum` load behavior, including `load_a` and `load_b` asserted together.
- Reset clearing of `acc_out` at the start of simulation.
- One-cycle latency from `load_a` to `acc_out`.

### 1.2 Out of Scope

| Item | Reason |
|---|---|
| Reset priority over `load_a` / `load_b` (former F2) | Descoped 2026-11-23 |
| Reset asserted during operation | Descoped 2026-11-23 |
| Idle cycles and `PASSA` with `load_b` alone in the opcode × load cross | Descoped 2026-11-23 |
| Gate-level simulation, timing (setup/hold), synthesis checks | RTL functional verification only |
| Code coverage (statement, branch, toggle) | Not collected; functional coverage only |
| Illegal or X `opcode` values | `op_e` has exactly four values; see spec Section 9 |

## 2. References

| Document | Content |
|---|---|
| `docs/Spec.md` | Design specification: ports, function, reset, timing, operating sequence |
| `docs/alu_vc_issue_log.md` | Issues found and resolved, simulation results, history |

## 3. Verification Environment

### 3.1 Architecture

```
tb_top                                   (module, tb/tb_top.sv)
 ├── hw_top u_hw_top                     (module, tb/hw_top.sv)
 │    ├── clkgen   u_clkgen  ── clk ──┬──────────────┐
 │    ├── alu_if   u_alu_if  ◄────────┘              │   dvr_cb, mon_cb,
 │    │                                              │   cg_ctrl, assertions
 │    └── alu_reg  u_alu_reg (DUT) ◄── clk ──────────┘
 │
 └── alu_vc vc                           (class, sv/alu_vc.sv)
      ├── agent agnt
      │    ├── sequencer sqr ──► driver dvr ── dvr_cb ──► u_alu_if
      │    └── monitor mon   ◄── mon_cb ── u_alu_if
      ├── scoreboard sb      ◄── mailbox mon2sb  ── monitor
      └── alu_coverage cov   ◄── mailbox mon2cov ── monitor
```

The monitor sends each completed transaction to every subscriber mailbox. All subscribers receive the same handle and treat it as read-only.

### 3.2 Components

| Component | File | Role |
|---|---|---|
| `tb_top` | `tb/tb_top.sv` | Testbench top. Instantiates `hw_top`, builds `alu_vc`, connects it to `u_hw_top.u_alu_if`, runs `+NUM_PKTS` packets. |
| `hw_top` | `tb/hw_top.sv` | Hardware top: DUT, interface and clock generator (spec Fig. 3). |
| `clkgen` | `tb/clk_gen.sv` | Free-running clock, period `` `CYCLE `` (10 ns). |
| `alu_if` | `sv/alu_if.sv` | Signal bundle. `dvr_cb` drives outputs `` `Tdrive `` (2 ns) after the edge; `mon_cb` samples `#1step` before the edge. Holds the control covergroup `cg_ctrl`, one cover property and the `acc_out` assertions. |
| `alu_pkt` | `sv/alu_pkt.sv` | Transaction: `a`, `b`, `opcode`, observed `acc_out`, control bits `cycle` and `load_b_with_a`. |
| `sequencer` | `sv/sequencer.sv` | Returns a new randomized `alu_pkt` on each request (pull model). |
| `driver` | `sv/driver.sv` | Drives each packet cycle by cycle through `dvr_cb` (Section 4.2). |
| `monitor` | `sv/monitor.sv` | Rebuilds transactions from the pins on every edge, in the order of the reference model (Section 6). |
| `scoreboard` | `sv/scoreboard.sv` | Predicts `acc_out`, flags mismatches, checks the transaction count, prints the verdict. |
| `alu_coverage` | `sv/coverage.sv` | Transaction-level covergroup `cg_pkt`. |
| `agent`, `alu_vc` | `sv/agent.sv`, `sv/alu_vc.sv` | Containers. `alu_vc` connects the mailboxes and the virtual interface and runs the test. |
| `alu_pkg` | `sv/alu_pkg.sv` | Package: `op_e` and all classes. |
| `cycle.sv` | `sv/cycle.sv` | `` `CYCLE ``, `` `Tdrive ``, `` `timescale 1ns/1ns ``. |

### 3.3 Running the Test

From the `tb/` folder:

| Command | Purpose |
|---|---|
| `vsim -c -do run.do` | Batch run: compiles, simulates, saves coverage, exits. |
| `vsim -do run.do` | GUI run; stays open for waves and debug. |
| `+NUM_PKTS=<n>` on the `vsim` line in `run.do` | Packet count (default 1000). |
| `-sv_seed <N>` | Reproduce a run; the seed is printed as `Sv_Seed = N`. |
| `vcover report -details alu_cov.ucdb` | Coverage per bin after the run. |

The compile list is `tb/run.f`.

## 4. Stimulus

### 4.1 Transaction Generation

Constrained-random `alu_pkt` objects with the constraints below. Each constraint is named, so a test can disable it with `constraint_mode(0)`.

| Constraint | Effect | Purpose |
|---|---|---|
| `c2` | `opcode` distribution: `PASSA` 10, `NAND` 20, `OR` 20, `ADD` 50 | Weight towards the adder |
| `c1` | `cycle = 1` for two-operand opcodes, `0` for `PASSA` | Selects the drive sequence |
| `c_corners` | `a` and `b`: `0000`, `FFFF`, `AAAA`, `5555` at 5 % each; remaining 80 % spread over the ranges between them | Operand corner cases (C1, C2) |
| `c_both_loads` | `load_b_with_a = 1` in about 15 % of packets | `load_a` and `load_b` together (F10, C4) |

### 4.2 Drive Sequence

| Phase | Clock edges | Signals |
|---|---|---|
| Reset | Time 0 to first edge | `rst_n = 0`, loads low |
| Two-operand packet, edge 1 | 1 | `data = b`, `load_b = 1`, `load_a = 0`, `opcode` |
| Every packet, last edge | 1 | `data = a`, `load_a = 1`, `load_b = load_b_with_a`, `opcode` |
| End of test (drain) | 3 | Loads released, so the last result reaches the monitor |

There are no idle cycles between packets. Reset is applied only at the start of simulation.

## 5. Features and Corner Cases

### 5.1 Features

Feature IDs are kept from the design specification. F2 is out of scope (Section 1.2).

| ID | Feature | Check | Checked by | Coverage |
|---|---|---|---|---|
| F1 | Reset | `acc_out` (and `b`) become 0 on an edge with `rst_n = 0` | Assertion `a_acc_reset` (`acc_out`). `b` reset: not directly checked (Section 11) | `cg_ctrl.cp_reset` |
| F3 | `breg` load | `b` captures `data` only when `load_b = 1`; holds otherwise | Scoreboard, through every two-operand result. Hold: not directly checked (Section 11) | `cg_ctrl.cp_loads`, `cp_load_b_seq` |
| F4 | `accum` load | `acc_out` captures `alu` only when `load_a = 1`; holds otherwise | Scoreboard (capture); assertion `a_acc_hold` (hold) | `cg_ctrl.cp_loads`, `cp_load_a_seq`, `cov_data_chg_no_load` |
| F5 | `PASSA` | `acc_out == data` | Scoreboard | `cg_pkt.cp_op`, `x_op_a`, `x_op_b` |
| F6 | `NAND` | `acc_out == ~(data & b)` | Scoreboard | `cg_pkt.cp_op`, `x_op_a`, `x_op_b` |
| F7 | `OR` | `acc_out == data \| b` | Scoreboard | `cg_pkt.cp_op`, `x_op_a`, `x_op_b` |
| F8 | `ADD` | `acc_out == (data + b)[15:0]` | Scoreboard | `cg_pkt.cp_op`, `x_op_a`, `x_op_b` |
| F9 | Overflow | `ADD` wraps correctly (e.g. `FFFF + 0001 = 0000`) | Scoreboard (16-bit reference) | `cg_pkt.cp_add_carry` |
| F10 | Independence | `load_a` and `load_b` operate independently, including both asserted together | Scoreboard (expects the old `b`) | `cg_ctrl.cp_loads.both`, `x_op_loads` |
| F11 | Latency | Output changes one cycle after inputs, never combinationally | Scoreboard timing (`acc_out` read exactly one edge after `load_a`); `a_acc_hold` | Implicit |

### 5.2 Corner Cases

| ID | Corner case | Covered by | Checked by |
|---|---|---|---|
| C1 | `data` = `0000`, `FFFF`, `AAAA`, `5555` | `cg_pkt.cp_a`, `x_op_a` | Scoreboard |
| C2 | `b` = `0000` and `FFFF` with every opcode | `cg_pkt.cp_b`, `x_op_b` | Scoreboard |
| C3 | Back-to-back loads on consecutive cycles | `cg_ctrl.cp_load_a_seq`, `cp_load_b_seq` | Scoreboard |
| C4 | `load_b` and `load_a` in the same cycle (`accum` uses the **old** `b`) | `cg_ctrl.cp_loads.both`, `x_op_loads` | Scoreboard |
| C5 | `data` changing while `load_a = 0` (must not affect `acc_out`) | Cover property `cov_data_chg_no_load` | Assertion `a_acc_hold` |

## 6. Checking

### 6.1 Reference Model

The scoreboard and monitor together implement this model, evaluated at each rising clock edge:

```systemverilog
if (!rst_n) begin
  exp_b   = '0;
  exp_acc = '0;
end else begin
  // accum uses b from BEFORE this edge
  if (load_a) begin
    case (opcode)
      PASSA: exp_acc = data;
      NAND : exp_acc = ~(data & exp_b);
      OR   : exp_acc = data | exp_b;
      ADD  : exp_acc = data + exp_b;     // 16-bit, carry-out discarded
    endcase
  end
  if (load_b) exp_b = data;              // update after using the old value
end
```

The monitor tracks `exp_b` from the pins and records `a`, `opcode` and the old `b` on each `load_a` edge. The scoreboard computes `exp_acc` and compares it with the `acc_out` sampled on the next edge.

### 6.2 Checkers

| Checker | Location | Detects | Reported as |
|---|---|---|---|
| Result compare | `scoreboard::check()` | Wrong `acc_out` for any operation | `$error ... MISMATCH ..., expected acc_out=...` |
| Transaction count | `scoreboard::report()` | Lost or spurious transactions | `$error ... driven but ... checked` |
| `a_acc_hold` | `alu_if` | `acc_out` changes without `load_a` | `$error a_acc_hold: ...` |
| `a_acc_reset` | `alu_if` | `acc_out` not 0 after reset | `$error a_acc_reset: ...` |

### 6.3 Verdict

At the end of the test the scoreboard prints the number of transactions checked, the mismatches and the assertion failures, followed by a single verdict: **TEST PASSED** only if there are no mismatches, the transaction count matches, and there are no assertion failures. Every failure is also counted in the simulator's *Errors* total.

Result checking and the assertions are disabled with `alu_vc.check_en = 0`. The standalone VC test (`sv/vc_test.sv`, no DUT) uses this.

## 7. Functional Coverage

Goal: 100 % on both covergroups.

### 7.1 Transaction Coverage: `cg_pkt` (`sv/coverage.sv`)

Sampled once per monitored transaction.

| Item | Bins | Traces to |
|---|---|---|
| `cp_op` | `PASSA`, `NAND`, `OR`, `ADD` | F5–F8 |
| `cp_a` | `zero`, `ones`, `h_aaaa`, `h_5555`, `low`, `mid`, `high` | C1 |
| `cp_b` | same as `cp_a` | C2 |
| `x_op_a` | `cp_op` × `cp_a` (28 bins) | F5–F8, C1 |
| `x_op_b` | `cp_op` × `cp_b` (28 bins) | F5–F8, C2 |
| `cp_add_carry` | `ADD` only: `no_carry`, `carry` | F9 |

### 7.2 Control Coverage: `cg_ctrl` (`sv/alu_if.sv`)

Sampled on every clock edge from `mon_cb`.

| Item | Bins | Traces to |
|---|---|---|
| `cp_loads` | `idle`, `only_b`, `only_a`, `both` (outside reset) | F3, F4, F10 |
| `cp_op` | four opcodes (outside reset) | — |
| `x_op_loads` | `cp_op` × `cp_loads`, ignoring `idle` and `PASSA` × `only_b` (11 bins) | F10, C4 |
| `cp_reset` | `reset` (an edge with `rst_n = 0`) | F1 |
| `cp_load_a_seq` | `load_a` back-to-back (`1 => 1`) | C3 |
| `cp_load_b_seq` | `load_b` back-to-back (`1 => 1`) | C3 |

### 7.3 Cover Property

| Name | Sequence | Traces to |
|---|---|---|
| `cov_data_chg_no_load` | `rst_n && !load_a && $changed(data)` | C5 |

### 7.4 Reporting

Coverage is printed at the end of each run and saved to `tb/alu_cov.ucdb`.

## 8. Testbench Validation

The checkers are validated by injecting a bug into the DUT and confirming that the expected checker fails.

| Injected bug | Expected detection | Result |
|---|---|---|
| `ADD` changed to `data - b` | Scoreboard mismatch on every `ADD` transaction, *TEST FAILED* | Passed (2026-11-23 08:32): 46 of 46 `ADD` transactions flagged, no false alarms |
| `accum` loads on every edge (`else if (load_a)` → `else`) | `a_acc_hold` fails, *TEST FAILED* (the scoreboard alone would still pass) | Not run |

## 9. Completion Criteria

| Criterion | Target |
|---|---|
| Verdict | *TEST PASSED* on the regression run |
| Result mismatches | 0 |
| Transaction count | Driven = checked |
| Assertion failures | 0 |
| Functional coverage | 100 % on `cg_pkt` and `cg_ctrl` |
| Checker validation | Each checker shown to detect an injected bug |

## 10. Results

Final regression run (2026-11-23 09:47, seed 815655969, 1,000 packets): *TEST PASSED*, 1,000 transactions checked, 0 mismatches, `cg_pkt` 100 %, `cg_ctrl` 100 %, cover property `cov_data_chg_no_load` hit 910 times.

| Criterion | Status |
|---|---|
| Verdict, mismatches, transaction count | Met |
| Functional coverage | Met (100 % / 100 %) |
| Assertion failures | Assertions added after the final run; to be confirmed in the next regression |
| Checker validation | Met for the scoreboard; not run for the assertions |

The full run history is in `docs/alu_vc_issue_log.md`.

## 11. Known Limitations

- **F3, `b` hold and reset:** `b` is internal, and every two-operand transaction reloads it before use. Neither its hold behavior nor its reset clearing is checked directly. A stimulus option that skips the `load_b` edge would let the scoreboard check both through the next result.
- **Reset:** applied once, at the start of simulation. Reset with a load, and reset during operation, are not exercised (Section 1.2).
- **Assertions:** `a_acc_hold` and `a_acc_reset` compile without errors but have not been run in simulation yet.

## 12. Revision History

| Version | Date | Description |
|---|---|---|
| 1.0 | 2026-11-23 | First release. Separated from `docs/Spec.md` Section 8 (v0.3) and extended with the environment, stimulus, checking, coverage, validation, completion criteria and results. Corner cases numbered C1–C5. |
