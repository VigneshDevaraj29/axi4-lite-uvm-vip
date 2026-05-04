

`ifndef AXI4_LITE_PKG_SV
`define AXI4_LITE_PKG_SV

package axi4_lite_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ------------------------------------------------------------
  // AXI operation type
  // ------------------------------------------------------------
  typedef enum {
    AXI_READ,
    AXI_WRITE
  } axi_op_e;

  // ------------------------------------------------------------
  // AXI4-Lite transaction class
  // ------------------------------------------------------------
  class axi4_lite_txn extends uvm_sequence_item;

    rand axi_op_e op;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;

    bit [31:0] read_data;
    bit [1:0]  resp;

    // Valid register addresses for normal tests
    constraint valid_addr_c {
      addr inside {
        32'h0000_0000,
        32'h0000_0004,
        32'h0000_0008,
        32'h0000_000C
      };
    }

    // Default full-word write
    constraint strb_c {
      strb == 4'b1111;
    }

    `uvm_object_utils_begin(axi4_lite_txn)
      `uvm_field_enum(axi_op_e, op, UVM_ALL_ON)
      `uvm_field_int(addr,      UVM_ALL_ON)
      `uvm_field_int(data,      UVM_ALL_ON)
      `uvm_field_int(strb,      UVM_ALL_ON)
      `uvm_field_int(read_data, UVM_ALL_ON)
      `uvm_field_int(resp,      UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4_lite_txn");
      super.new(name);
    endfunction

  endclass

    // ------------------------------------------------------------
  // AXI4-Lite Sequencer
  // ------------------------------------------------------------
  class axi4_lite_sequencer extends uvm_sequencer #(axi4_lite_txn);

    `uvm_component_utils(axi4_lite_sequencer)

    function new(string name = "axi4_lite_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction

  endclass


  // ------------------------------------------------------------
  // Basic AXI4-Lite Sequence
  // Generates one write followed by one read
  // ------------------------------------------------------------
  class axi4_lite_basic_sequence extends uvm_sequence #(axi4_lite_txn);

    `uvm_object_utils(axi4_lite_basic_sequence)

    function new(string name = "axi4_lite_basic_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_lite_txn txn;

      // ----------------------------
      // Write transaction
      // ----------------------------
      txn = axi4_lite_txn::type_id::create("write_txn");

      start_item(txn);

      txn.op   = AXI_WRITE;
      txn.addr = 32'h0000_0000;
      txn.data = 32'h1234_ABCD;
      txn.strb = 4'b1111;

      finish_item(txn);

      `uvm_info("BASIC_SEQ", "Generated WRITE transaction", UVM_MEDIUM)


      // ----------------------------
      // Read transaction
      // ----------------------------
      txn = axi4_lite_txn::type_id::create("read_txn");

      start_item(txn);

      txn.op   = AXI_READ;
      txn.addr = 32'h0000_0000;
      txn.data = 32'h0000_0000;
      txn.strb = 4'b0000;

      finish_item(txn);

      `uvm_info("BASIC_SEQ", "Generated READ transaction", UVM_MEDIUM)

    endtask
endclass

  // ------------------------------------------------------------
  // Multi Register Sequence
  // Writes and reads all 4 valid registers
  // ------------------------------------------------------------
  class axi4_lite_multi_reg_sequence extends uvm_sequence #(axi4_lite_txn);

    `uvm_object_utils(axi4_lite_multi_reg_sequence)

    function new(string name = "axi4_lite_multi_reg_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_lite_txn txn;

      bit [31:0] addr_list [4] = '{
        32'h0000_0000,
        32'h0000_0004,
        32'h0000_0008,
        32'h0000_000C
      };

      bit [31:0] data_list [4] = '{
        32'h1111_AAAA,
        32'h2222_BBBB,
        32'h3333_CCCC,
        32'h4444_DDDD
      };

      // Write all 4 registers
      foreach (addr_list[i]) begin
        txn = axi4_lite_txn::type_id::create($sformatf("write_txn_%0d", i));

        start_item(txn);

        txn.op   = AXI_WRITE;
        txn.addr = addr_list[i];
        txn.data = data_list[i];
        txn.strb = 4'b1111;

        finish_item(txn);

        `uvm_info("MULTI_REG_SEQ",
                  $sformatf("Generated WRITE addr=0x%08h data=0x%08h",
                            addr_list[i], data_list[i]),
                  UVM_MEDIUM)
      end

      // Read all 4 registers
      foreach (addr_list[i]) begin
        txn = axi4_lite_txn::type_id::create($sformatf("read_txn_%0d", i));

        start_item(txn);

        txn.op   = AXI_READ;
        txn.addr = addr_list[i];
        txn.data = 32'h0000_0000;
        txn.strb = 4'b0000;

        finish_item(txn);

        `uvm_info("MULTI_REG_SEQ",
                  $sformatf("Generated READ addr=0x%08h", addr_list[i]),
                  UVM_MEDIUM)
      end
    endtask

  endclass
  // ------------------------------------------------------------
  // Invalid Address Sequence
  // Checks SLVERR response for unmapped address
  // ------------------------------------------------------------
  class axi4_lite_invalid_addr_sequence extends uvm_sequence #(axi4_lite_txn);

    `uvm_object_utils(axi4_lite_invalid_addr_sequence)

    function new(string name = "axi4_lite_invalid_addr_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_lite_txn txn;

      // Invalid write to address 0x10
      txn = axi4_lite_txn::type_id::create("invalid_write_txn");

      start_item(txn);

      txn.op   = AXI_WRITE;
      txn.addr = 32'h0000_0010;
      txn.data = 32'hDEAD_BEEF;
      txn.strb = 4'b1111;

      finish_item(txn);

      `uvm_info("INVALID_ADDR_SEQ",
                "Generated invalid WRITE to address 0x00000010",
                UVM_MEDIUM)


      // Invalid read from address 0x10
      txn = axi4_lite_txn::type_id::create("invalid_read_txn");

      start_item(txn);

      txn.op   = AXI_READ;
      txn.addr = 32'h0000_0010;
      txn.data = 32'h0000_0000;
      txn.strb = 4'b0000;

      finish_item(txn);

      `uvm_info("INVALID_ADDR_SEQ",
                "Generated invalid READ from address 0x00000010",
                UVM_MEDIUM)

    endtask

  endclass

  // ------------------------------------------------------------
  // WSTRB Partial Write Sequence
  // Checks byte-enable behavior
  // ------------------------------------------------------------
  class axi4_lite_wstrb_sequence extends uvm_sequence #(axi4_lite_txn);

    `uvm_object_utils(axi4_lite_wstrb_sequence)

    function new(string name = "axi4_lite_wstrb_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_lite_txn txn;

      // Step 1: Full write to initialize reg0
      txn = axi4_lite_txn::type_id::create("full_write_txn");

      start_item(txn);

      txn.op   = AXI_WRITE;
      txn.addr = 32'h0000_0000;
      txn.data = 32'hAAAA_BBBB;
      txn.strb = 4'b1111;

      finish_item(txn);

      `uvm_info("WSTRB_SEQ",
                "Generated full WRITE addr=0x00000000 data=0xAAAA_BBBB strb=1111",
                UVM_MEDIUM)


      // Step 2: Partial write, only lowest byte should update
      txn = axi4_lite_txn::type_id::create("partial_write_txn");

      start_item(txn);

      txn.op   = AXI_WRITE;
      txn.addr = 32'h0000_0000;
      txn.data = 32'h1234_5678;
      txn.strb = 4'b0001;

      finish_item(txn);

      `uvm_info("WSTRB_SEQ",
                "Generated partial WRITE addr=0x00000000 data=0x1234_5678 strb=0001",
                UVM_MEDIUM)


      // Step 3: Read back reg0
      txn = axi4_lite_txn::type_id::create("read_back_txn");

      start_item(txn);

      txn.op   = AXI_READ;
      txn.addr = 32'h0000_0000;
      txn.data = 32'h0000_0000;
      txn.strb = 4'b0000;

      finish_item(txn);

      `uvm_info("WSTRB_SEQ",
                "Generated READ back from addr=0x00000000",
                UVM_MEDIUM)

    endtask

  endclass

    // ------------------------------------------------------------
  // Random Write/Read Sequence
  // Performs constrained-random writes followed by reads
  // ------------------------------------------------------------
  class axi4_lite_random_sequence extends uvm_sequence #(axi4_lite_txn);

    `uvm_object_utils(axi4_lite_random_sequence)

    function new(string name = "axi4_lite_random_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_lite_txn txn;
      bit [31:0] rand_addr;
      bit [31:0] rand_data;
      bit [3:0]  rand_strb;

      repeat (20) begin

        // ----------------------------
        // Random WRITE transaction
        // ----------------------------
        txn = axi4_lite_txn::type_id::create("random_write_txn");

        start_item(txn);

        if (!txn.randomize() with {
          op == AXI_WRITE;
          addr inside {
            32'h0000_0000,
            32'h0000_0004,
            32'h0000_0008,
            32'h0000_000C
          };
          strb inside {[4'b0001:4'b1111]};
        }) begin
          `uvm_error("RAND_SEQ", "Randomization failed for WRITE transaction")
        end

        rand_addr = txn.addr;
        rand_data = txn.data;
        rand_strb = txn.strb;

        finish_item(txn);

        `uvm_info("RAND_SEQ",
                  $sformatf("Generated RANDOM WRITE addr=0x%08h data=0x%08h strb=0x%0h",
                            rand_addr, rand_data, rand_strb),
                  UVM_MEDIUM)


        // ----------------------------
        // READ back from same address
        // ----------------------------
        txn = axi4_lite_txn::type_id::create("random_read_txn");

        start_item(txn);

        txn.op   = AXI_READ;
        txn.addr = rand_addr;
        txn.data = 32'h0000_0000;
        txn.strb = 4'b0000;

        finish_item(txn);

        `uvm_info("RAND_SEQ",
                  $sformatf("Generated READ BACK addr=0x%08h", rand_addr),
                  UVM_MEDIUM)

      end
    endtask

  endclass
      // ------------------------------------------------------------
  // AXI4-Lite Driver
  // Converts sequence transactions into pin-level AXI activity
  // ------------------------------------------------------------
  class axi4_lite_driver extends uvm_driver #(axi4_lite_txn);

    `uvm_component_utils(axi4_lite_driver)

    virtual axi4_lite_if.master vif;

    function new(string name = "axi4_lite_driver", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual axi4_lite_if.master)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NOVIF", "Virtual interface not found for axi4_lite_driver")
      end
    endfunction

    task run_phase(uvm_phase phase);
      axi4_lite_txn txn;

      reset_signals();

      forever begin
        seq_item_port.get_next_item(txn);

        if (txn.op == AXI_WRITE) begin
          drive_write(txn);
        end
        else begin
          drive_read(txn);
        end

        seq_item_port.item_done();
      end
    endtask

    task reset_signals();
      vif.AWADDR  <= '0;
      vif.AWVALID <= 1'b0;

      vif.WDATA   <= '0;
      vif.WSTRB   <= '0;
      vif.WVALID  <= 1'b0;

      vif.BREADY  <= 1'b0;

      vif.ARADDR  <= '0;
      vif.ARVALID <= 1'b0;

      vif.RREADY  <= 1'b0;

      wait (vif.ARESETn == 1'b1);
      @(posedge vif.ACLK);
    endtask

    task drive_write(axi4_lite_txn txn);
      `uvm_info("AXI_DRIVER", $sformatf("Driving WRITE addr=0x%08h data=0x%08h", txn.addr, txn.data), UVM_MEDIUM)

      @(posedge vif.ACLK);

      vif.AWADDR  <= txn.addr;
      vif.AWVALID <= 1'b1;

      vif.WDATA   <= txn.data;
      vif.WSTRB   <= txn.strb;
      vif.WVALID  <= 1'b1;

      wait (vif.AWREADY == 1'b1);
      @(posedge vif.ACLK);
      vif.AWVALID <= 1'b0;

      wait (vif.WREADY == 1'b1);
      @(posedge vif.ACLK);
      vif.WVALID <= 1'b0;

      vif.BREADY <= 1'b1;
      wait (vif.BVALID == 1'b1);

      txn.resp = vif.BRESP;

      @(posedge vif.ACLK);
      vif.BREADY <= 1'b0;

      `uvm_info("AXI_DRIVER", $sformatf("WRITE complete BRESP=0x%0h", txn.resp), UVM_MEDIUM)
    endtask

    task drive_read(axi4_lite_txn txn);
      `uvm_info("AXI_DRIVER", $sformatf("Driving READ addr=0x%08h", txn.addr), UVM_MEDIUM)

      @(posedge vif.ACLK);

      vif.ARADDR  <= txn.addr;
      vif.ARVALID <= 1'b1;

      wait (vif.ARREADY == 1'b1);
      @(posedge vif.ACLK);
      vif.ARVALID <= 1'b0;

      vif.RREADY <= 1'b1;
      wait (vif.RVALID == 1'b1);

      txn.read_data = vif.RDATA;
      txn.resp      = vif.RRESP;

      @(posedge vif.ACLK);
      vif.RREADY <= 1'b0;

      `uvm_info("AXI_DRIVER", $sformatf("READ complete RDATA=0x%08h RRESP=0x%0h", txn.read_data, txn.resp), UVM_MEDIUM)
    endtask

  endclass

    // ------------------------------------------------------------
  // AXI4-Lite Monitor
  // Observes AXI bus activity and creates transactions
  // ------------------------------------------------------------
  class axi4_lite_monitor extends uvm_monitor;

    `uvm_component_utils(axi4_lite_monitor)

    virtual axi4_lite_if.monitor vif;

    uvm_analysis_port #(axi4_lite_txn) mon_ap;

    function new(string name = "axi4_lite_monitor", uvm_component parent);
      super.new(name, parent);
      mon_ap = new("mon_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual axi4_lite_if.monitor)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NOVIF", "Virtual interface not found for axi4_lite_monitor")
      end
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(posedge vif.ACLK);

        if (vif.ARESETn) begin
          monitor_write();
          monitor_read();
        end
      end
    endtask

    task monitor_write();
      axi4_lite_txn txn;

      if (vif.AWVALID && vif.AWREADY && vif.WVALID && vif.WREADY) begin
        txn = axi4_lite_txn::type_id::create("mon_write_txn");

        txn.op   = AXI_WRITE;
        txn.addr = vif.AWADDR;
        txn.data = vif.WDATA;
        txn.strb = vif.WSTRB;

        wait (vif.BVALID && vif.BREADY);
        txn.resp = vif.BRESP;

        mon_ap.write(txn);

        `uvm_info("AXI_MONITOR",
                  $sformatf("Observed WRITE addr=0x%08h data=0x%08h resp=0x%0h",
                            txn.addr, txn.data, txn.resp),
                  UVM_MEDIUM)
      end
    endtask

    task monitor_read();
      axi4_lite_txn txn;

      if (vif.ARVALID && vif.ARREADY) begin
        txn = axi4_lite_txn::type_id::create("mon_read_txn");

        txn.op   = AXI_READ;
        txn.addr = vif.ARADDR;

        wait (vif.RVALID && vif.RREADY);

        txn.read_data = vif.RDATA;
        txn.resp      = vif.RRESP;

        mon_ap.write(txn);

        `uvm_info("AXI_MONITOR",
                  $sformatf("Observed READ addr=0x%08h data=0x%08h resp=0x%0h",
                            txn.addr, txn.read_data, txn.resp),
                  UVM_MEDIUM)
      end
    endtask

  endclass

 
    // ------------------------------------------------------------
  // AXI4-Lite Scoreboard
  // Checks write/read correctness using expected register model
  // ------------------------------------------------------------
  class axi4_lite_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi4_lite_scoreboard)

    uvm_analysis_imp #(axi4_lite_txn, axi4_lite_scoreboard) sb_imp;

    bit [31:0] expected_regs [4];

    function new(string name = "axi4_lite_scoreboard", uvm_component parent);
      super.new(name, parent);
      sb_imp = new("sb_imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      foreach (expected_regs[i]) begin
        expected_regs[i] = 32'h0000_0000;
      end
    endfunction

    function bit is_valid_addr(bit [31:0] addr);
      return (addr == 32'h0000_0000 ||
              addr == 32'h0000_0004 ||
              addr == 32'h0000_0008 ||
              addr == 32'h0000_000C);
    endfunction

    function int addr_to_index(bit [31:0] addr);
      return addr[3:2];
    endfunction

    function bit [31:0] apply_wstrb(
      bit [31:0] old_data,
      bit [31:0] new_data,
      bit [3:0]  strb
    );
      bit [31:0] result;

      result = old_data;

      for (int i = 0; i < 4; i++) begin
        if (strb[i]) begin
          result[i*8 +: 8] = new_data[i*8 +: 8];
        end
      end

      return result;
    endfunction

    function void write(axi4_lite_txn txn);
      int idx;

      if (txn.op == AXI_WRITE) begin
        if (is_valid_addr(txn.addr)) begin
          idx = addr_to_index(txn.addr);

          expected_regs[idx] = apply_wstrb(
            expected_regs[idx],
            txn.data,
            txn.strb
          );

          if (txn.resp == 2'b00) begin
            `uvm_info("SCOREBOARD",
                      $sformatf("WRITE PASS addr=0x%08h data=0x%08h",
                                txn.addr, txn.data),
                      UVM_MEDIUM)
          end
          else begin
            `uvm_error("SCOREBOARD",
                       $sformatf("WRITE FAIL: Expected OKAY, got resp=0x%0h",
                                 txn.resp))
          end
        end
        else begin
          if (txn.resp == 2'b10) begin
            `uvm_info("SCOREBOARD",
                      $sformatf("INVALID WRITE PASS addr=0x%08h returned SLVERR",
                                txn.addr),
                      UVM_MEDIUM)
          end
          else begin
            `uvm_error("SCOREBOARD",
                       $sformatf("INVALID WRITE FAIL addr=0x%08h resp=0x%0h",
                                 txn.addr, txn.resp))
          end
        end
      end

      else if (txn.op == AXI_READ) begin
        if (is_valid_addr(txn.addr)) begin
          idx = addr_to_index(txn.addr);

          if (txn.read_data == expected_regs[idx] && txn.resp == 2'b00) begin
            `uvm_info("SCOREBOARD",
                      $sformatf("READ PASS addr=0x%08h expected=0x%08h actual=0x%08h",
                                txn.addr, expected_regs[idx], txn.read_data),
                      UVM_MEDIUM)
          end
          else begin
            `uvm_error("SCOREBOARD",
                       $sformatf("READ FAIL addr=0x%08h expected=0x%08h actual=0x%08h resp=0x%0h",
                                 txn.addr, expected_regs[idx], txn.read_data, txn.resp))
          end
        end
        else begin
          if (txn.resp == 2'b10) begin
            `uvm_info("SCOREBOARD",
                      $sformatf("INVALID READ PASS addr=0x%08h returned SLVERR",
                                txn.addr),
                      UVM_MEDIUM)
          end
          else begin
            `uvm_error("SCOREBOARD",
                       $sformatf("INVALID READ FAIL addr=0x%08h resp=0x%0h",
                                 txn.addr, txn.resp))
          end
        end
      end
    endfunction

  endclass
  // ------------------------------------------------------------
  // AXI4-Lite Functional Coverage Collector
  // Samples monitored transactions
  // ------------------------------------------------------------
  class axi4_lite_coverage extends uvm_subscriber #(axi4_lite_txn);

    `uvm_component_utils(axi4_lite_coverage)

    axi_op_e sample_op;
    bit [31:0] sample_addr;
    bit [31:0] sample_data;
    bit [3:0]  sample_strb;
    bit [1:0]  sample_resp;

    covergroup axi_cg;

      option.per_instance = 1;

      // Operation coverage
      op_cp: coverpoint sample_op {
        bins read_op  = {AXI_READ};
        bins write_op = {AXI_WRITE};
      }

      // Address coverage
      addr_cp: coverpoint sample_addr {
        bins reg0_addr    = {32'h0000_0000};
        bins reg1_addr    = {32'h0000_0004};
        bins reg2_addr    = {32'h0000_0008};
        bins reg3_addr    = {32'h0000_000C};
        bins invalid_addr = default;
      }

      // Response coverage
      resp_cp: coverpoint sample_resp {
        bins okay_resp   = {2'b00};
        bins slverr_resp = {2'b10};
      }

      // Write strobe coverage
      strb_cp: coverpoint sample_strb {
        bins no_strobe = {4'b0000};
        bins byte0     = {4'b0001};
        bins byte1     = {4'b0010};
        bins byte2     = {4'b0100};
        bins byte3     = {4'b1000};
        bins full_word = {4'b1111};
        bins others    = default;
      }

      // Cross coverage
      op_addr_cross: cross op_cp, addr_cp;
      op_resp_cross: cross op_cp, resp_cp;

    endgroup

    function new(string name = "axi4_lite_coverage", uvm_component parent);
      super.new(name, parent);
      axi_cg = new();
    endfunction

    function void write(axi4_lite_txn txn);

      sample_op   = txn.op;
      sample_addr = txn.addr;
      sample_data = txn.data;
      sample_strb = txn.strb;
      sample_resp = txn.resp;

      axi_cg.sample();

      `uvm_info("COVERAGE",
                $sformatf("Sampled txn op=%s addr=0x%08h strb=0x%0h resp=0x%0h coverage=%0.2f%%",
                          txn.op.name(), txn.addr, txn.strb, txn.resp, axi_cg.get_coverage()),
                UVM_LOW)

    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      `uvm_info("COVERAGE",
                $sformatf("Final AXI4-Lite functional coverage = %0.2f%%",
                          axi_cg.get_coverage()),
                UVM_NONE)
    endfunction

  endclass
  // ------------------------------------------------------------
  // AXI4-Lite Agent
  // Contains sequencer, driver, and monitor
  // ------------------------------------------------------------
  class axi4_lite_agent extends uvm_agent;

    `uvm_component_utils(axi4_lite_agent)

    axi4_lite_sequencer sequencer;
    axi4_lite_driver    driver;
    axi4_lite_monitor   monitor;

    function new(string name = "axi4_lite_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      sequencer = axi4_lite_sequencer::type_id::create("sequencer", this);
      driver    = axi4_lite_driver   ::type_id::create("driver", this);
      monitor   = axi4_lite_monitor  ::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

  endclass


  // ------------------------------------------------------------
  // AXI4-Lite Environment
  // Contains agent and scoreboard
  // ------------------------------------------------------------
  class axi4_lite_env extends uvm_env;

    `uvm_component_utils(axi4_lite_env)

    axi4_lite_agent      agent;
    axi4_lite_scoreboard scoreboard;
    axi4_lite_coverage   coverage;

    function new(string name = "axi4_lite_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      agent      = axi4_lite_agent     ::type_id::create("agent", this);
      scoreboard = axi4_lite_scoreboard::type_id::create("scoreboard", this);
      coverage   = axi4_lite_coverage  ::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      agent.monitor.mon_ap.connect(scoreboard.sb_imp);
      agent.monitor.mon_ap.connect(coverage.analysis_export);
    endfunction

  endclass

    // ------------------------------------------------------------
  // AXI4-Lite Basic Test
  // Creates environment and starts basic sequence
  // ------------------------------------------------------------
  class axi4_lite_basic_test extends uvm_test;

    `uvm_component_utils(axi4_lite_basic_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_basic_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = axi4_lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      axi4_lite_basic_sequence seq;

      phase.raise_objection(this);

      `uvm_info("BASIC_TEST", "Starting AXI4-Lite basic test", UVM_MEDIUM)

      seq = axi4_lite_basic_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);

      #100ns;

      `uvm_info("BASIC_TEST", "Finished AXI4-Lite basic test", UVM_MEDIUM)

      phase.drop_objection(this);
    endtask

  endclass
  // ------------------------------------------------------------
  // AXI4-Lite Multi Register Test
  // Runs multi register sequence
  // ------------------------------------------------------------
  class axi4_lite_multi_reg_test extends uvm_test;

    `uvm_component_utils(axi4_lite_multi_reg_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_multi_reg_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = axi4_lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      axi4_lite_multi_reg_sequence seq;

      phase.raise_objection(this);

      `uvm_info("MULTI_REG_TEST", "Starting AXI4-Lite multi register test", UVM_MEDIUM)

      seq = axi4_lite_multi_reg_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);

      #100ns;

      `uvm_info("MULTI_REG_TEST", "Finished AXI4-Lite multi register test", UVM_MEDIUM)

      phase.drop_objection(this);
    endtask

  endclass

  // ------------------------------------------------------------
  // AXI4-Lite Invalid Address Test
  // Runs invalid address sequence
  // ------------------------------------------------------------
  class axi4_lite_invalid_addr_test extends uvm_test;

    `uvm_component_utils(axi4_lite_invalid_addr_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_invalid_addr_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = axi4_lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      axi4_lite_invalid_addr_sequence seq;

      phase.raise_objection(this);

      `uvm_info("INVALID_ADDR_TEST", "Starting AXI4-Lite invalid address test", UVM_MEDIUM)

      seq = axi4_lite_invalid_addr_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);

      #100ns;

      `uvm_info("INVALID_ADDR_TEST", "Finished AXI4-Lite invalid address test", UVM_MEDIUM)

      phase.drop_objection(this);
    endtask

  endclass 
  // ------------------------------------------------------------
  // AXI4-Lite WSTRB Partial Write Test
  // Runs WSTRB sequence
  // ------------------------------------------------------------
  class axi4_lite_wstrb_test extends uvm_test;

    `uvm_component_utils(axi4_lite_wstrb_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_wstrb_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = axi4_lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      axi4_lite_wstrb_sequence seq;

      phase.raise_objection(this);

      `uvm_info("WSTRB_TEST", "Starting AXI4-Lite WSTRB partial write test", UVM_MEDIUM)

      seq = axi4_lite_wstrb_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);

      #100ns;

      `uvm_info("WSTRB_TEST", "Finished AXI4-Lite WSTRB partial write test", UVM_MEDIUM)

      phase.drop_objection(this);
    endtask

  endclass
  // ------------------------------------------------------------
  // AXI4-Lite Random Test
  // Runs constrained-random write/read sequence
  // ------------------------------------------------------------
  class axi4_lite_random_test extends uvm_test;

    `uvm_component_utils(axi4_lite_random_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_random_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = axi4_lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      axi4_lite_random_sequence seq;

      phase.raise_objection(this);

      `uvm_info("RAND_TEST", "Starting AXI4-Lite random write/read test", UVM_MEDIUM)

      seq = axi4_lite_random_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);

      #200ns;

      `uvm_info("RAND_TEST", "Finished AXI4-Lite random write/read test", UVM_MEDIUM)

      phase.drop_objection(this);
    endtask

  endclass
endpackage

`endif