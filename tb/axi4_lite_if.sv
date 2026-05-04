

`ifndef AXI4_LITE_IF_SV
`define AXI4_LITE_IF_SV

interface axi4_lite_if #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  input logic ACLK,
  input logic ARESETn
);

  // Write Address Channel
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic                  AWVALID;
  logic                  AWREADY;

  // Write Data Channel
  logic [DATA_WIDTH-1:0]     WDATA;
  logic [(DATA_WIDTH/8)-1:0] WSTRB;
  logic                      WVALID;
  logic                      WREADY;

  // Write Response Channel
  logic [1:0] BRESP;
  logic       BVALID;
  logic       BREADY;

  // Read Address Channel
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic                  ARVALID;
  logic                  ARREADY;

  // Read Data Channel
  logic [DATA_WIDTH-1:0] RDATA;
  logic [1:0]            RRESP;
  logic                  RVALID;
  logic                  RREADY;

  // Master side: used by TB/UVM driver
  modport master (
    input  ACLK,
    input  ARESETn,

    output AWADDR,
    output AWVALID,
    input  AWREADY,

    output WDATA,
    output WSTRB,
    output WVALID,
    input  WREADY,

    input  BRESP,
    input  BVALID,
    output BREADY,

    output ARADDR,
    output ARVALID,
    input  ARREADY,

    input  RDATA,
    input  RRESP,
    input  RVALID,
    output RREADY
  );

  // Slave side: used by RTL DUT
  modport slave (
    input  ACLK,
    input  ARESETn,

    input  AWADDR,
    input  AWVALID,
    output AWREADY,

    input  WDATA,
    input  WSTRB,
    input  WVALID,
    output WREADY,

    output BRESP,
    output BVALID,
    input  BREADY,

    input  ARADDR,
    input  ARVALID,
    output ARREADY,

    output RDATA,
    output RRESP,
    output RVALID,
    input  RREADY
  );

  // Monitor side: used later by UVM monitor
  modport monitor (
    input ACLK,
    input ARESETn,

    input AWADDR,
    input AWVALID,
    input AWREADY,

    input WDATA,
    input WSTRB,
    input WVALID,
    input WREADY,

    input BRESP,
    input BVALID,
    input BREADY,

    input ARADDR,
    input ARVALID,
    input ARREADY,

    input RDATA,
    input RRESP,
    input RVALID,
    input RREADY
  );

endinterface

`endif