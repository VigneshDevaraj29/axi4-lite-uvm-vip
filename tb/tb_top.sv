

module tb_top;

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

  // ------------------------------------------------------------
  // Clock generation: 10 ns clock period
  // ------------------------------------------------------------
  initial begin
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK;
  end

  // ------------------------------------------------------------
  // Reset task
  // ------------------------------------------------------------
  task reset_dut();
    begin
      ARESETn = 1'b0;

      axi_if.AWADDR  = '0;
      axi_if.AWVALID = 1'b0;

      axi_if.WDATA   = '0;
      axi_if.WSTRB   = '0;
      axi_if.WVALID  = 1'b0;

      axi_if.BREADY  = 1'b0;

      axi_if.ARADDR  = '0;
      axi_if.ARVALID = 1'b0;

      axi_if.RREADY  = 1'b0;

      repeat (5) @(posedge ACLK);
      ARESETn = 1'b1;
      repeat (2) @(posedge ACLK);
    end
  endtask

  // ------------------------------------------------------------
  // AXI4-Lite write task
  // ------------------------------------------------------------
  task axi_write(
    input logic [31:0] addr,
    input logic [31:0] data,
    input logic [3:0]  strb
  );
    begin
      @(posedge ACLK);

      // Drive write address channel
      axi_if.AWADDR  <= addr;
      axi_if.AWVALID <= 1'b1;

      // Drive write data channel
      axi_if.WDATA   <= data;
      axi_if.WSTRB   <= strb;
      axi_if.WVALID  <= 1'b1;

      // Wait until address handshake
      wait (axi_if.AWREADY == 1'b1);
      @(posedge ACLK);
      axi_if.AWVALID <= 1'b0;

      // Wait until data handshake
      wait (axi_if.WREADY == 1'b1);
      @(posedge ACLK);
      axi_if.WVALID <= 1'b0;

      // Wait for write response
      axi_if.BREADY <= 1'b1;
      wait (axi_if.BVALID == 1'b1);
      @(posedge ACLK);

      if (axi_if.BRESP == 2'b00) begin
        $display("[%0t] WRITE OKAY: addr=0x%08h data=0x%08h", $time, addr, data);
      end
      else begin
        $display("[%0t] WRITE ERROR: addr=0x%08h BRESP=0x%0h", $time, addr, axi_if.BRESP);
      end

      axi_if.BREADY <= 1'b0;

      @(posedge ACLK);
    end
  endtask

  // ------------------------------------------------------------
  // AXI4-Lite read task
  // ------------------------------------------------------------
  task axi_read(
    input  logic [31:0] addr,
    output logic [31:0] data
  );
    begin
      @(posedge ACLK);

      // Drive read address channel
      axi_if.ARADDR  <= addr;
      axi_if.ARVALID <= 1'b1;

      // Wait until read address handshake
      wait (axi_if.ARREADY == 1'b1);
      @(posedge ACLK);
      axi_if.ARVALID <= 1'b0;

      // Wait for read data
      axi_if.RREADY <= 1'b1;
      wait (axi_if.RVALID == 1'b1);
      data = axi_if.RDATA;

      @(posedge ACLK);

      if (axi_if.RRESP == 2'b00) begin
        $display("[%0t] READ OKAY : addr=0x%08h data=0x%08h", $time, addr, data);
      end
      else begin
        $display("[%0t] READ ERROR: addr=0x%08h RRESP=0x%0h", $time, addr, axi_if.RRESP);
      end

      axi_if.RREADY <= 1'b0;

      @(posedge ACLK);
    end
  endtask

  // ------------------------------------------------------------
  // Main test
  // ------------------------------------------------------------
  initial begin
    logic [31:0] read_data;

    $display("--------------------------------------------------");
    $display(" Starting AXI4-Lite Manual Testbench");
    $display("--------------------------------------------------");

    reset_dut();

    axi_write(32'h0000_0000, 32'h1234_ABCD, 4'b1111);
    axi_read (32'h0000_0000, read_data);

    if (read_data == 32'h1234_ABCD) begin
      $display("--------------------------------------------------");
      $display(" TEST PASSED: Read data matches written data");
      $display("--------------------------------------------------");
    end
    else begin
      $display("--------------------------------------------------");
      $display(" TEST FAILED: Expected 0x1234_ABCD, Got 0x%08h", read_data);
      $display("--------------------------------------------------");
    end

    #50;
    $finish;
  end

endmodule