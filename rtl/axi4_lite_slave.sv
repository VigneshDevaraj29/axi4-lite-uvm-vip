

`ifndef AXI4_LITE_SLAVE_SV
`define AXI4_LITE_SLAVE_SV

module axi4_lite_slave #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  axi4_lite_if.slave axi_if
);

  // ------------------------------------------------------------
  // AXI response encodings
  // ------------------------------------------------------------
  localparam logic [1:0] AXI_OKAY   = 2'b00;
  localparam logic [1:0] AXI_SLVERR = 2'b10;

  // ------------------------------------------------------------
  // Internal register block
  // ------------------------------------------------------------
  logic [DATA_WIDTH-1:0] reg0;
  logic [DATA_WIDTH-1:0] reg1;
  logic [DATA_WIDTH-1:0] reg2;
  logic [DATA_WIDTH-1:0] reg3;

  // Temporary storage for accepted write address and data
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic [DATA_WIDTH-1:0] wdata_reg;
  logic [(DATA_WIDTH/8)-1:0] wstrb_reg;

  logic aw_hs_done;
  logic w_hs_done;

  // ------------------------------------------------------------
  // Function: check valid register address
  // Valid addresses: 0x00, 0x04, 0x08, 0x0C
  // ------------------------------------------------------------
  function logic is_valid_addr(input logic [ADDR_WIDTH-1:0] addr);
    case (addr[5:0])
      6'h00,
      6'h04,
      6'h08,
      6'h0C: is_valid_addr = 1'b1;
      default: is_valid_addr = 1'b0;
    endcase
  endfunction

  // ------------------------------------------------------------
  // Task-like function: apply byte strobes for partial writes
  // ------------------------------------------------------------
  function logic [DATA_WIDTH-1:0] apply_wstrb(
    input logic [DATA_WIDTH-1:0] old_data,
    input logic [DATA_WIDTH-1:0] new_data,
    input logic [(DATA_WIDTH/8)-1:0] strb
  );
    logic [DATA_WIDTH-1:0] result;
    int i;

    begin
      result = old_data;
      for (i = 0; i < DATA_WIDTH/8; i++) begin
        if (strb[i]) begin
          result[i*8 +: 8] = new_data[i*8 +: 8];
        end
      end
      return result;
    end
  endfunction

  // ------------------------------------------------------------
  // Write channel logic
  // ------------------------------------------------------------
  always_ff @(posedge axi_if.ACLK or negedge axi_if.ARESETn) begin
    if (!axi_if.ARESETn) begin
      axi_if.AWREADY <= 1'b0;
      axi_if.WREADY  <= 1'b0;
      axi_if.BVALID  <= 1'b0;
      axi_if.BRESP   <= AXI_OKAY;

      awaddr_reg     <= '0;
      wdata_reg      <= '0;
      wstrb_reg      <= '0;

      aw_hs_done     <= 1'b0;
      w_hs_done      <= 1'b0;

      reg0           <= '0;
      reg1           <= '0;
      reg2           <= '0;
      reg3           <= '0;
    end
    else begin
      // Default ready behavior: accept when not already processing a write response
      axi_if.AWREADY <= (!aw_hs_done && !axi_if.BVALID);
      axi_if.WREADY  <= (!w_hs_done  && !axi_if.BVALID);

      // Capture write address handshake
      if (axi_if.AWVALID && axi_if.AWREADY) begin
        awaddr_reg <= axi_if.AWADDR;
        aw_hs_done <= 1'b1;
      end

      // Capture write data handshake
      if (axi_if.WVALID && axi_if.WREADY) begin
        wdata_reg  <= axi_if.WDATA;
        wstrb_reg  <= axi_if.WSTRB;
        w_hs_done  <= 1'b1;
      end

      // Once both address and data are captured, perform write and generate response
      if (aw_hs_done && w_hs_done && !axi_if.BVALID) begin
        if (is_valid_addr(awaddr_reg)) begin
          case (awaddr_reg[5:0])
            6'h00: reg0 <= apply_wstrb(reg0, wdata_reg, wstrb_reg);
            6'h04: reg1 <= apply_wstrb(reg1, wdata_reg, wstrb_reg);
            6'h08: reg2 <= apply_wstrb(reg2, wdata_reg, wstrb_reg);
            6'h0C: reg3 <= apply_wstrb(reg3, wdata_reg, wstrb_reg);
            default: ;
          endcase
          axi_if.BRESP <= AXI_OKAY;
        end
        else begin
          axi_if.BRESP <= AXI_SLVERR;
        end

        axi_if.BVALID <= 1'b1;
      end

      // Complete write response handshake
      if (axi_if.BVALID && axi_if.BREADY) begin
        axi_if.BVALID <= 1'b0;
        axi_if.BRESP  <= AXI_OKAY;

        aw_hs_done    <= 1'b0;
        w_hs_done     <= 1'b0;
      end
    end
  end

  // ------------------------------------------------------------
  // Read channel logic
  // ------------------------------------------------------------
  always_ff @(posedge axi_if.ACLK or negedge axi_if.ARESETn) begin
    if (!axi_if.ARESETn) begin
      axi_if.ARREADY <= 1'b0;
      axi_if.RVALID  <= 1'b0;
      axi_if.RRESP   <= AXI_OKAY;
      axi_if.RDATA   <= '0;
    end
    else begin
      // Ready to accept read address when no read response is pending
      axi_if.ARREADY <= !axi_if.RVALID;

      // Capture read address and return data
      if (axi_if.ARVALID && axi_if.ARREADY) begin
        if (is_valid_addr(axi_if.ARADDR)) begin
          case (axi_if.ARADDR[5:0])
            6'h00: axi_if.RDATA <= reg0;
            6'h04: axi_if.RDATA <= reg1;
            6'h08: axi_if.RDATA <= reg2;
            6'h0C: axi_if.RDATA <= reg3;
            default: axi_if.RDATA <= '0;
          endcase
          axi_if.RRESP <= AXI_OKAY;
        end
        else begin
          axi_if.RDATA <= '0;
          axi_if.RRESP <= AXI_SLVERR;
        end

        axi_if.RVALID <= 1'b1;
      end

      // Complete read data handshake
      if (axi_if.RVALID && axi_if.RREADY) begin
        axi_if.RVALID <= 1'b0;
        axi_if.RRESP  <= AXI_OKAY;
        axi_if.RDATA  <= '0;
      end
    end
  end

endmodule

`endif