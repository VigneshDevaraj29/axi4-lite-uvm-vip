

module uvm_tb_top;

  import uvm_pkg::*;
  import axi4_lite_pkg::*;

  `include "uvm_macros.svh"

  // ------------------------------------------------------------
  // Clock and reset
  // ------------------------------------------------------------
  logic ACLK;
  logic ARESETn;

  // ------------------------------------------------------------
  // Instantiate AXI4-Lite interface
  // ------------------------------------------------------------
  axi4_lite_if axi_if (
    .ACLK    (ACLK),
    .ARESETn (ARESETn)
  );

  // ------------------------------------------------------------
  // Instantiate DUT
  // ------------------------------------------------------------
    axi4_lite_slave dut (
    .axi_if (axi_if)
  );

  axi4_lite_assertions axi_assertions (
    .axi_if (axi_if)
  );
  

  // ------------------------------------------------------------
  // Clock generation: 10 ns clock period
  // ------------------------------------------------------------
  initial begin
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK;
  end

  // ------------------------------------------------------------
  // Reset generation
  // ------------------------------------------------------------
  initial begin
    ARESETn = 1'b0;
    repeat (5) @(posedge ACLK);
    ARESETn = 1'b1;
  end

  // ------------------------------------------------------------
  // Connect virtual interfaces to UVM components
  // ------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual axi4_lite_if.master)::set(
      null,
      "uvm_test_top.env.agent.driver",
      "vif",
      axi_if
    );

    uvm_config_db#(virtual axi4_lite_if.monitor)::set(
      null,
      "uvm_test_top.env.agent.monitor",
      "vif",
      axi_if
    );
  end

  // ------------------------------------------------------------
  // Start UVM test
  // ------------------------------------------------------------
  initial begin
    run_test("axi4_lite_basic_test");
  end
  // ------------------------------------------------------------
  // Waveform dump
  // ------------------------------------------------------------
  initial begin
    $dumpfile("axi4_lite_uvm.vcd");
    $dumpvars(0, uvm_tb_top);
  end

endmodule