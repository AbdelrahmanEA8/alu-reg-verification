/*-----------------------------------------------------------------------------
 File        : scoreboard.sv
 Description : ALU scoreboard. Receives each completed transaction from the
               monitor through a mailbox, predicts acc_out from a, b and
               opcode (16-bit reference model), and reports every mismatch
               with $error. report() checks the transaction count against
               the number driven, includes the interface assertion failures,
               and prints a single PASS/FAIL verdict.
-----------------------------------------------------------------------------*/

class scoreboard extends component_base;
  mailbox #(alu_pkt) mon2sb;     // from the monitor, connected by alu_vc
  int unsigned       n_checked;  // transactions compared
  int unsigned       n_errors;   // acc_out mismatches

  function new(string name, component_base parent);
    super.new(name, parent);
  endfunction

  // Reference model: the result alu_reg must capture on load_a
  function bit [15:0] predict(alu_pkt pkt);
    case (pkt.opcode)
      PASSA:   return pkt.a;
      NAND:    return ~(pkt.a & pkt.b);
      OR:      return pkt.a | pkt.b;
      ADD:     return pkt.a + pkt.b;      // carry-out dropped (16-bit)
      default: return '0;
    endcase
  endfunction

  task run();
    alu_pkt pkt;
    forever begin
      mon2sb.get(pkt);                    // blocks until the monitor sends one
      check(pkt);
    end
  endtask

  function void check(alu_pkt pkt);
    bit [15:0] exp = predict(pkt);
    n_checked++;
    if (pkt.acc_out !== exp) begin
      n_errors++;
      $error("%s: @%0t: MISMATCH %s, expected acc_out=%h",
             pathname(), $time, pkt.sprint(), exp);
    end
  endfunction

  // Called by alu_vc after the driver has drained
  function void report(int unsigned n_driven, int unsigned n_assert_errors = 0);
    if (n_checked != n_driven)
      $error("%s: %0d transactions driven but %0d checked",
             pathname(), n_driven, n_checked);
    $display("===============================");
    $display("Scoreboard report: %0d checked, %0d mismatches", n_checked, n_errors);
    $display("Assertion failures: %0d", n_assert_errors);
    if (n_errors == 0 && n_checked == n_driven && n_assert_errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $display("===============================");
  endfunction
endclass
