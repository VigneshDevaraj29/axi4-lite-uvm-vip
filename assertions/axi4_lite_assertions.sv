module axi4_lite_assertions (
  axi4_lite_if.monitor axi_if
);

  // ------------------------------------------------------------
  // AWVALID must remain high until AWREADY
  // ------------------------------------------------------------
  property awvalid_stable_until_awready;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.AWVALID && !axi_if.AWREADY |=> axi_if.AWVALID;
  endproperty

  assert property (awvalid_stable_until_awready)
    else $error("ASSERTION FAILED: AWVALID dropped before AWREADY");


  // ------------------------------------------------------------
  // WVALID must remain high until WREADY
  // ------------------------------------------------------------
  property wvalid_stable_until_wready;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.WVALID && !axi_if.WREADY |=> axi_if.WVALID;
  endproperty

  assert property (wvalid_stable_until_wready)
    else $error("ASSERTION FAILED: WVALID dropped before WREADY");


  // ------------------------------------------------------------
  // ARVALID must remain high until ARREADY
  // ------------------------------------------------------------
  property arvalid_stable_until_arready;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.ARVALID && !axi_if.ARREADY |=> axi_if.ARVALID;
  endproperty

  assert property (arvalid_stable_until_arready)
    else $error("ASSERTION FAILED: ARVALID dropped before ARREADY");


  // ------------------------------------------------------------
  // BVALID must remain high until BREADY
  // ------------------------------------------------------------
  property bvalid_stable_until_bready;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.BVALID && !axi_if.BREADY |=> axi_if.BVALID;
  endproperty

  assert property (bvalid_stable_until_bready)
    else $error("ASSERTION FAILED: BVALID dropped before BREADY");


  // ------------------------------------------------------------
  // RVALID must remain high until RREADY
  // ------------------------------------------------------------
  property rvalid_stable_until_rready;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.RVALID && !axi_if.RREADY |=> axi_if.RVALID;
  endproperty

  assert property (rvalid_stable_until_rready)
    else $error("ASSERTION FAILED: RVALID dropped before RREADY");


  // ------------------------------------------------------------
  // Valid response values only: OKAY or SLVERR
  // ------------------------------------------------------------
  property valid_bresp;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.BVALID |-> axi_if.BRESP inside {2'b00, 2'b10};
  endproperty

  assert property (valid_bresp)
    else $error("ASSERTION FAILED: Invalid BRESP value");


  property valid_rresp;
    @(posedge axi_if.ACLK)
    disable iff (!axi_if.ARESETn)
    axi_if.RVALID |-> axi_if.RRESP inside {2'b00, 2'b10};
  endproperty

  assert property (valid_rresp)
    else $error("ASSERTION FAILED: Invalid RRESP value");

endmodule