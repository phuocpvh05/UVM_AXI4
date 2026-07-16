// =============================================================================
// axi4_pkg.sv
// Tất cả file con nằm cùng thư mục tb/ — include phẳng, không cần subfolder
// Thứ tự include theo dependency: item → base → sequences → drv/mon
//                                → sb/cov → agent → env
// =============================================================================
`ifndef AXI4_PKG_SV
`define AXI4_PKG_SV

package axi4_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // =========================================================================
    // Parameters dùng toàn project
    // =========================================================================
    parameter int DATA_WIDTH = 32;
    parameter int ADDR_WIDTH = 32;
    parameter int ID_WIDTH   = 4;
    parameter int NUM_REGS   = 16;
    parameter int BASE_ADDR  = 32'h0000_0000;

    // =========================================================================
    // Include theo thứ tự dependency (tất cả nằm cùng folder tb/)
    // =========================================================================
    `include "axi4_seq_item.sv"

    `include "axi4_base_seq.sv"
    `include "axi4_single_write_seq.sv"
    `include "axi4_single_read_seq.sv"
    `include "axi4_burst_write_seq.sv"
    `include "axi4_burst_read_seq.sv"
    `include "axi4_random_seq.sv"
    `include "axi4_direct_seq.sv"
    `include "axi4_directed_coverage_seq.sv"

    `include "axi4_driver.sv"
    `include "axi4_monitor.sv"

    `include "axi4_scoreboard.sv"
    `include "axi4_coverage.sv"

    `include "axi4_agent.sv"
    `include "axi4_env.sv"

endpackage : axi4_pkg

`endif
