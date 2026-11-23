# ALU Verification Component — Issue Log

| | |
|---|---|
| **Component** | ALU verification component (`sv/`): sequencer, driver, monitor, agent, `alu_vc`; standalone test `alu_test` (`sv/vc_test.sv`) |
| **DUT** | `alu_reg` (`tb/`), integrated through `hw_top` |
| **Testbench** | `tb/tb_top.sv` (top) with `tb/run.f` and `tb/run.do`; run from `tb/` with `vsim -c -do run.do` |
| **Reference** | `docs/Spec.md` (design specification, v0.4: timing §6–§7, Fig. 3) |
| **Verification plan** | `docs/alu_reg_verification_plan.md` (v1.0). Spec Section 8 references in this log (8.1–8.4, v0.3) now correspond to plan Sections 5–7 and 6.1 |
| **Tools** | QuestaSim-64 2021.1; slang (static SV checks) |
| **Last updated** | 2026-11-23 |

## 1. Status

| Open | High | Med | Low | Resolved |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 18 |

**Verification closed (2026-11-23).** All issues are closed. The VC is integrated with the DUT, the testbench is self-checking, and the coverage goals of the verification plan (spec v0.3) are met. The last run (09:47) drove 1,000 transactions with 0 mismatches (*TEST PASSED*) and reached 100 % on both covergroups (`cg_pkt` and `cg_ctrl`). The scoreboard was shown to catch an injected DUT bug with no false alarms. Two `acc_out` assertions (F1, F4) were added afterwards and compile cleanly, but haven't been run in simulation (VC-35). All source files carry a standard header with the file name and description.

**Outstanding at closure:** the first future regression should show *Assertion failures: 0* with *TEST PASSED*, confirming the VC-35 assertions in simulation.

**Known limitation (accepted at closure):** F3 (`b` holds and clears on reset) has no direct checker. `b` is internal, and every two-operand packet reloads it before use. A `reuse_b` stimulus option (a two-operand op without the `load_b` edge) would let the scoreboard check it through the next result.

**Severity:** **High** — wrong results, or lost or spurious transactions · **Med** — blocks integration or gives misleading output · **Low** — cleanup or enhancement.

## 2. Open issues

| ID | Sev | Area | Description | Planned action |
|---|---|---|---|---|
| — | — | — | None. All issues are closed. | — |

## 3. Resolved issues

| ID | Sev | Area | Issue | Resolution | Closed |
|---|---|---|---|---|---|
| VC-35 | Med | Checking | The scoreboard reads `acc_out` only on the edge after `load_a`, so a DUT that changed `acc_out` while `load_a = 0` (F4), or didn't clear it on reset (F1), would still pass. | Two assertions added in `alu_if`: `a_acc_hold` `(rst_n && !load_a) \|=> $stable(acc_out)` and `a_acc_reset` `!rst_n \|=> acc_out == '0`. Failures are counted and included in the scoreboard's verdict. They are disabled with `check_en = 0` (no DUT). Compiles without errors or warnings. **Closed without a simulation run, at the user's decision.** Confirmation is left to the next regression (*Assertion failures: 0*). | 2026-11-23 |
| VC-26 | Low | Stimulus and coverage scope | The random stimulus couldn't reach several spec cases: operand corners, both loads on one edge, ADD wrap to zero, idle cycles, reset with a load, reset during a run. | (1) Weighted operand corners (`c_corners`: `0000`, `FFFF`, `AAAA`, `5555` at 5 % each). (2) Both loads on one edge (`load_b_with_a`, about 15 %, spec F10); the monitor records it and `sprint()` prints it. (3) ADD overflow coverage simplified to *no carry / carry*. (4) Scope reduced (spec v0.3): F2 (reset priority), reset during a run, idle cycles and PASSA-with-only-`load_b` removed from the plan and the coverage model. Confirmed in the 09:47 run: `cg_pkt` 100 %, `cg_ctrl` 100 %, *TEST PASSED* on 1,000 transactions. | 2026-11-23 |
| VC-34 | Med | Coverage | There was no functional coverage, so there was no way to measure which spec features, corner cases and crosses the stimulus reaches. | Coverage model added. `alu_coverage` (transaction level, fed by its own monitor mailbox): opcodes, operand corner and range bins, opcode × operand crosses, ADD carry and wrap. `cg_ctrl` in `alu_if` (every clock edge on `mon_cb`): load combinations, opcode × `load_a` × `load_b`, reset with loads, back-to-back loads. Two cover properties with hit counters. The monitor sends each packet to a list of subscriber mailboxes. End-of-test report, and UCDB saved by `run.do`. First run (08:52) reported correctly: all percentages match an independent recount from the transcript. | 2026-11-23 |
| VC-27 | Low | Debug output | `alu_pkt::printmsg()` passed one more argument than its format string expected (an extra `$time`), so every printed field would be shifted. | Extra `$time` removed. Format string and arguments now match (4 and 4). The function is kept for debug use. | 2026-11-23 |
| VC-33 | Med | Checking | The testbench wasn't self-checking: nothing compared `acc_out` with an expected value during simulation, so a wrong DUT result still ended with *Errors: 0*. | `sv/scoreboard.sv` added. The monitor sends each packet through a mailbox (`mon2sb`, connected in `alu_vc`). A 16-bit reference model predicts `acc_out`, every mismatch raises `$error`, and `report()` checks the transaction count and prints *TEST PASSED/FAILED*. `check_en = 0` disables checking for the standalone test. Validated with a passing run (08:29) and a bug-injection run (08:32), in which all 46 ADD transactions were flagged and none of the others. | 2026-11-23 |
| VC-29 | Med | Integration | The standalone test used its own clock and interface, so the VC couldn't drive the DUT. | `tb/tb_top.sv` instantiates `hw_top` and configures the VC with `u_hw_top.u_alu_if`. The packet count is set with `+NUM_PKTS` (default 100). `run.f` and `run.do` moved to `tb/` with top `tb_top`. The first integrated run (08:13) passed: 100/100 transactions, all `acc_out` values correct. | 2026-11-23 |
| VC-21 | High | Monitor | Transactions were decoded from `opcode` alone: `load_a`, `load_b` and `rst_n` were ignored, and the interface was sampled at t=0 before any clock edge. Reset and idle cycles were reported as transactions (two spurious packets at start-up). | Monitor rewritten to decode one edge at a time, in spec §8.4 order: complete the pending result from `acc_out` → skip reset edges (clear the `b` copy) → on `load_a`, record `a` and `opcode` with the previous `b` → on `load_b`, update the `b` copy. Idle and reset edges no longer produce transactions. | 2026-11-21 |
| VC-22 | Med | Driver | After the last packet, `load_a` stayed asserted, so the DUT re-captured on every following edge. The monitor reported dozens of spurious transactions during the end-of-test delay. | Driver ends with a drain: release `load_a` and `load_b`, then wait two cycles so the final result reaches the monitor. | 2026-11-21 |
| VC-11 | High | Monitor | After reading a result, the monitor waited one extra edge before starting the next transaction. Back-to-back transactions were misaligned (`a` recorded as `b`). | The edge that completes one transaction is also decoded for the next one (kept in the VC-21 rewrite). | 2026-11-20 |
| VC-12 | High | Test / driver | `$finish` executed on the same edge the last packet was scheduled, so that packet never reached the DUT. | Initially a fixed `#1000ns` delay; replaced by the driver drain (VC-22). `$finish` now follows the drain directly. | 2026-11-21 |
| VC-13 | High | Test clock | The test clock generator produced a high pulse of zero width. | Rewritten as `initial` + `forever` toggle. | 2026-11-20 |
| VC-24 | Low | Test clock | The test clock toggled every `CYCLE`, giving a 20 ns period, while `Tdrive` and `clk_gen` treat `CYCLE` as the full period (10 ns). | Toggle every `CYCLE/2`. Clock period is now 10 ns everywhere. | 2026-11-23 |
| VC-16 | Low | Clock / config | `clk_gen.sv` unconditionally redefined `CYCLE`, which could silently override `+define+CYCLE=…` or the guarded value in `cycle.sv`. | `clk_gen.sv` takes `CYCLE` from `cycle.sv`, the single source for `CYCLE`, `Tdrive` and the timescale. | 2026-11-23 |
| VC-15 | Med | Integration (`hw_top.sv`) | `hw_top` had ports and connected `alu_if` by port, which didn't match the interface or spec Fig. 3. | `hw_top` made portless, per Fig. 3: `clkgen` drives a local clock, `alu_if u_alu_if(clk)`, and `alu_reg` is connected to the interface signals. | 2026-11-23 |
| VC-17 | Low | Packages | The interface and DUT import the testbench package (`alu_pkg`) for `op_e`, and `alu_pkg` refers back to the interface: a circular dependency. | Accepted as is: a single `op_e` in `alu_pkg`, and QuestaSim supports the structure. A separate types package would only be needed for tools that reject it. | 2026-11-23 |
| VC-14 | Med | Run scripts | `run.f` and `run.do` still targeted the previous lab (switch design, top `top`). | Retargeted to the ALU VC (`alu_pkg`, `alu_if`, `alu_test`). The DUT files are staged but disabled until VC-29. | 2026-11-21 |
| VC-30 | Low | Run scripts | The clean-library step failed on a locked library (`vdel-134`) and the run went ahead on a stale `work` without any error. | Library deletion removed. `work` is created only if it doesn't exist. | 2026-11-23 |
| VC-32 | Low | Run scripts | Batch runs didn't exit, an unconditional `quit` closed the GUI, and the script had stale options and comments. | `run.do` cleaned up: quits in batch mode only (the GUI stays open), redundant `-c` and `vmap` removed, and the seed is printed so a failing run can be repeated. | 2026-11-23 |

## 4. Simulation results

| Date | Configuration | Seed | Driven / monitored | Mismatches | Result |
|---|---|---|---|---|---|
| 2026-11-23 06:46 | VC standalone (no DUT), 20 ns clock | default | 100 / 100 | 0 | Pass |
| 2026-11-23 07:43 | VC standalone (no DUT), 10 ns clock | 832190013 | 100 / 100 | 0 | Pass |
| 2026-11-23 08:13 | Integrated: `tb_top` → `hw_top` → `alu_reg`, 10 ns clock | 1188779913 | 100 / 100 | 0 stimulus, 0 result | Pass |
| 2026-11-23 08:29 | Integrated, with scoreboard | 1283192481 | 100 / 100 | 0 (scoreboard: 100 checked) | Pass (*TEST PASSED*) |
| 2026-11-23 08:32 | Negative test: bug injected in `alu_reg` (ADD → `data - b`) | 484124737 | 100 / 100 | 46 = all 46 ADD; 0 others | Fail as expected (*TEST FAILED*, *Errors: 46*) |
| 2026-11-23 08:52 | Integrated, scoreboard and coverage | 2134652517 | 100 / 100 | 0 (scoreboard: 100 checked) | Pass. Coverage: `cg_pkt` 56.35 %, `cg_ctrl` 58.33 %; UCDB `tb/alu_cov.ucdb` |
| 2026-11-23 09:28 | Integrated, plus corner and both-loads stimulus (VC-26, part 1), 10,000 packets | 1727886589 | 10,000 / 10,000 | 0 (scoreboard: 10,000 checked) | Pass. Coverage: `cg_pkt` 94.44 %, `cg_ctrl` 83.33 % |
| 2026-11-23 09:47 | Integrated, final stimulus and coverage (spec v0.3), 1,000 packets | 815655969 | 1,000 / 1,000 | 0 (scoreboard: 1,000 checked) | Pass. Coverage: `cg_pkt` 100 %, `cg_ctrl` 100 % |

Checks performed (by script on the transcript): (1) each monitored transaction matches the driven one (`a`, `b`, `opcode`; for PASSA the expected `b` is the last loaded value); (2) integrated runs only: each `acc_out` equals the reference result for its opcode, computed in 16 bits. The 08:13 run covered ADD 55, OR 24, NAND 14 and PASSA 7, with 29 ADD results that wrap past 16 bits. Standalone runs have no DUT, so `acc_out` is `0000` there. From 08:29 on, the scoreboard checks results during simulation; the script check is kept as an independent cross-check (08:29: ADD 49, OR 22, NAND 19, PASSA 10; 23 ADD results wrap past 16 bits). 09:47 cross-check: all 1,000 results are correct, and `load_b_with_a` was driven on 130 packets and observed by the monitor on exactly those 130.

## 5. History

| Date | Milestone |
|---|---|
| 2026-11-20 | First review of the VC. Functional issues found in monitor timing, end-of-test handling and the test clock (VC-11, VC-12, VC-13). Run scripts and `hw_top` logged as integration blockers. |
| 2026-11-21 | Monitor decode rewritten to spec §8.4 (VC-21). Driver drain added (VC-22). Run scripts retargeted to the ALU VC (VC-14). |
| 2026-11-23 | First passing simulations (100/100 transactions). Clock period and `CYCLE` source aligned (VC-24, VC-16). `hw_top` restructured to Fig. 3 (VC-15). Run script cleaned up (VC-30, VC-32). |
| 2026-11-23 | Integration started (VC-29): `tb/tb_top.sv` added (instantiates `hw_top`, connects the VC to `u_hw_top.u_alu_if`, `+NUM_PKTS` run option). `run.f` and `run.do` moved to `tb/` and retargeted to `tb_top`. Standard file headers (file name + description) applied to all `sv/` and `tb/` sources. |
| 2026-11-23 | First integrated simulation passed: 100/100 transactions, all DUT results correct (VC-29 closed). Self-checking scoreboard logged as the next step (VC-33). |
| 2026-11-23 | Scoreboard added (VC-33): monitor → mailbox → `scoreboard` in `alu_vc`, with a reference model, per-transaction `$error`, a count check and a PASS/FAIL report. Result checking can be disabled for the standalone VC test (`check_en`). |
| 2026-11-23 | Scoreboard validated: passes on the correct DUT and flags every transaction affected by an injected ADD bug, with no false alarms (VC-33 closed). The testbench is now self-checking. |
| 2026-11-23 | `printmsg()` format fixed (VC-27). Functional coverage model added (VC-34): a transaction-level covergroup in `alu_coverage`, a control covergroup and cover properties in `alu_if`, and an end-of-test coverage report with UCDB saved by `run.do`. The monitor now sends each packet to a list of subscriber mailboxes. |
| 2026-11-23 | First coverage run (VC-34 closed): `cg_pkt` 56.35 %, `cg_ctrl` 58.33 %. The holes (operand corners, both loads together, reset with a load or during a run, back-to-back `load_b`, ADD wrap to zero) are assigned to VC-26. |
| 2026-11-23 | VC-26 part 1: weighted operand corners and both-loads-on-one-edge stimulus (F10). The 09:28 run passes on 10,000 transactions with `cg_pkt` at 94.44 % and `cg_ctrl` at 83.33 %. `sprint()` and the monitor now report `load_b_with_a`. Default packet count raised to 1000. |
| 2026-11-23 | ADD overflow coverage simplified to *no carry / carry* (wrap-to-zero bin merged into `carry`; F9 and 8.3 require overflow, not a specific sum). |
| 2026-11-23 | Verification scope reduced (spec v0.3): F2 (reset priority), *reset asserted mid-operation*, idle cycles and PASSA-with-only-`load_b` removed from the plan and from the coverage model. `cg_ctrl` report now also lists `cp_op`. |
| 2026-11-23 | Coverage closure: the 09:47 run reaches 100 % on `cg_pkt` and `cg_ctrl` with *TEST PASSED* on 1,000 transactions (VC-26 closed). All issues closed. |
| 2026-11-23 | `acc_out` assertions added in `alu_if` for F4 (hold) and F1 (reset), counted in the scoreboard's PASS/FAIL verdict (VC-35). |
| 2026-11-23 | Verification closed. All 18 issues resolved; coverage at 100 % (09:47 run). Outstanding: confirm the VC-35 assertions in the next regression. Accepted limitation: no direct checker for F3. |
