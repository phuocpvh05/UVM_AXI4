// =============================================================================
// AXI4 Full Interface
// 32-bit address / 32-bit data / 4-bit ID
// =============================================================================
`timescale 1ns/1ps
interface axi4_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input logic ACLK,
    input logic ARESETn
);

    // =========================================================================
    // Write Address
    // =========================================================================
    logic [ID_WIDTH-1:0]   AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0]            AWLEN;
    logic [2:0]            AWSIZE;
    logic [1:0]            AWBURST;
    logic                  AWVALID;
    logic                  AWREADY;

    // =========================================================================
    // Write Data
    // =========================================================================
    logic [DATA_WIDTH-1:0]   WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic                    WLAST;
    logic                    WVALID;
    logic                    WREADY;

    // =========================================================================
    // Write Response
    // =========================================================================
    logic [ID_WIDTH-1:0] BID;
    logic [1:0]          BRESP;
    logic                BVALID;
    logic                BREADY;

    // =========================================================================
    // Read Address
    // =========================================================================
    logic [ID_WIDTH-1:0]   ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0]            ARLEN;
    logic [2:0]            ARSIZE;
    logic [1:0]            ARBURST;
    logic                  ARVALID;
    logic                  ARREADY;

    // =========================================================================
    // Read Data
    // =========================================================================
    logic [ID_WIDTH-1:0]   RID;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RLAST;
    logic                  RVALID;
    logic                  RREADY;

    // =========================================================================
    // Master clocking block
    // Driver sử dụng block này
    // =========================================================================
    clocking master_cb @(posedge ACLK);
        default input #1step output #1;

        output AWID;
        output AWADDR;
        output AWLEN;
        output AWSIZE;
        output AWBURST;
        output AWVALID;
        input  AWREADY;

        output WDATA;
        output WSTRB;
        output WLAST;
        output WVALID;
        input  WREADY;

        input  BID;
        input  BRESP;
        input  BVALID;
        output BREADY;

        output ARID;
        output ARADDR;
        output ARLEN;
        output ARSIZE;
        output ARBURST;
        output ARVALID;
        input  ARREADY;

        input  RID;
        input  RDATA;
        input  RRESP;
        input  RLAST;
        input  RVALID;
        output RREADY;
    endclocking

    // =========================================================================
    // Monitor clocking block
    //
    // Tất cả tín hiệu đều là input.
    // Monitor không dùng master_cb vì AWVALID/WVALID/... là output clockvars
    // trong master_cb.
    // =========================================================================
    clocking monitor_cb @(posedge ACLK);
        default input #1step;

        input AWID;
        input AWADDR;
        input AWLEN;
        input AWSIZE;
        input AWBURST;
        input AWVALID;
        input AWREADY;

        input WDATA;
        input WSTRB;
        input WLAST;
        input WVALID;
        input WREADY;

        input BID;
        input BRESP;
        input BVALID;
        input BREADY;

        input ARID;
        input ARADDR;
        input ARLEN;
        input ARSIZE;
        input ARBURST;
        input ARVALID;
        input ARREADY;

        input RID;
        input RDATA;
        input RRESP;
        input RLAST;
        input RVALID;
        input RREADY;
    endclocking

    // =========================================================================
    // Modports
    // =========================================================================
    modport master_mp (
        clocking master_cb,
        input ACLK,
        input ARESETn
    );

    modport slave_mp (
        input  AWID,
        input  AWADDR,
        input  AWLEN,
        input  AWSIZE,
        input  AWBURST,
        input  AWVALID,
        output AWREADY,

        input  WDATA,
        input  WSTRB,
        input  WLAST,
        input  WVALID,
        output WREADY,

        output BID,
        output BRESP,
        output BVALID,
        input  BREADY,

        input  ARID,
        input  ARADDR,
        input  ARLEN,
        input  ARSIZE,
        input  ARBURST,
        input  ARVALID,
        output ARREADY,

        output RID,
        output RDATA,
        output RRESP,
        output RLAST,
        output RVALID,
        input  RREADY,

        input ACLK,
        input ARESETn
    );

    modport monitor_mp (
        clocking monitor_cb,
        input ACLK,
        input ARESETn
    );

endinterface : axi4_if
