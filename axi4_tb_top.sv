// =============================================================================
// Testbench Top  –  AXI4 Slave UVM Verification
// =============================================================================
`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import axi4_pkg::*;
`include "axi4_direct_test.sv"
`include "axi4_random_test.sv"

module axi4_tb_top;

    // -------------------------------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------------------------------
    logic ACLK;
    logic ARESETn;

    initial ACLK = 0;
    always #5 ACLK = ~ACLK;   // 100 MHz

    initial begin
        ARESETn = 0;
        repeat (10) @(posedge ACLK);
        ARESETn = 1;
    end

    // -------------------------------------------------------------------------
    // AXI4 Interface
    // -------------------------------------------------------------------------
    axi4_if #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .ID_WIDTH  (4)
    ) axi_bus (
        .ACLK   (ACLK),
        .ARESETn(ARESETn)
    );

    // -------------------------------------------------------------------------
    // DUT  –  AXI4 Slave
    // -------------------------------------------------------------------------
    axi4_slave #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .NUM_REGS  (16),
        .ID_WIDTH  (4)
    ) dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        .AWID    (axi_bus.AWID),
        .AWADDR  (axi_bus.AWADDR),
        .AWLEN   (axi_bus.AWLEN),
        .AWSIZE  (axi_bus.AWSIZE),
        .AWBURST (axi_bus.AWBURST),
        .AWVALID (axi_bus.AWVALID),
        .AWREADY (axi_bus.AWREADY),

        .WDATA   (axi_bus.WDATA),
        .WSTRB   (axi_bus.WSTRB),
        .WLAST   (axi_bus.WLAST),
        .WVALID  (axi_bus.WVALID),
        .WREADY  (axi_bus.WREADY),

        .BID     (axi_bus.BID),
        .BRESP   (axi_bus.BRESP),
        .BVALID  (axi_bus.BVALID),
        .BREADY  (axi_bus.BREADY),

        .ARID    (axi_bus.ARID),
        .ARADDR  (axi_bus.ARADDR),
        .ARLEN   (axi_bus.ARLEN),
        .ARSIZE  (axi_bus.ARSIZE),
        .ARBURST (axi_bus.ARBURST),
        .ARVALID (axi_bus.ARVALID),
        .ARREADY (axi_bus.ARREADY),

        .RID     (axi_bus.RID),
        .RDATA   (axi_bus.RDATA),
        .RRESP   (axi_bus.RRESP),
        .RLAST   (axi_bus.RLAST),
        .RVALID  (axi_bus.RVALID),
        .RREADY  (axi_bus.RREADY)
    );

    // -------------------------------------------------------------------------
    // UVM – pass virtual interface and run test
    // -------------------------------------------------------------------------
    initial begin
        uvm_config_db #(virtual axi4_if)::set(null, "*", "vif", axi_bus);
        run_test();
    end

    // -------------------------------------------------------------------------
    // Timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #500_000;
        `uvm_fatal("TIMEOUT","Simulation exceeded 500 us -  check for deadlock")
    end

    // -------------------------------------------------------------------------
    // Optional: waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("axi4_waves.vcd");
        $dumpvars(0, axi4_tb_top);
    end

endmodule : axi4_tb_top
