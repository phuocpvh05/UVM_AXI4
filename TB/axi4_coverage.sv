// =============================================================================
// axi4_coverage.sv
// Functional coverage collector
// Target: 100% trên mọi coverpoint và cross coverage
// =============================================================================
`ifndef AXI4_COVERAGE_SV
`define AXI4_COVERAGE_SV

class axi4_coverage extends uvm_subscriber #(axi4_seq_item);
    `uvm_component_utils(axi4_coverage)

    axi4_seq_item cov_item;

    // =========================================================================
    covergroup axi4_cg;

        // -----------------------------------------------------------------
        // Loại transaction: write vs read
        // -----------------------------------------------------------------
        cp_txn_type: coverpoint cov_item.is_write {
            bins write_txn = {1'b1};
            bins read_txn  = {1'b0};
        }

        // -----------------------------------------------------------------
        // Tất cả 16 register – bin riêng cho từng register
        // Mục tiêu: mọi register phải được truy cập
        // -----------------------------------------------------------------
        cp_addr: coverpoint (cov_item.addr - BASE_ADDR) >> 2 {
            bins reg_0  = {0};   bins reg_1  = {1};
            bins reg_2  = {2};   bins reg_3  = {3};
            bins reg_4  = {4};   bins reg_5  = {5};
            bins reg_6  = {6};   bins reg_7  = {7};
            bins reg_8  = {8};   bins reg_9  = {9};
            bins reg_10 = {10};  bins reg_11 = {11};
            bins reg_12 = {12};  bins reg_13 = {13};
            bins reg_14 = {14};  bins reg_15 = {15};
        }

        // -----------------------------------------------------------------
        // Burst length: single, 2-beat, 3-beat, 4-beat
        // -----------------------------------------------------------------
        cp_burst_len: coverpoint cov_item.burst_len {
            bins single  = {0};
            bins beat_2  = {1};
            bins beat_3  = {2};
            bins beat_4  = {3};
        }

        // -----------------------------------------------------------------
        // Burst type (phải luôn là INCR theo constraint)
        // -----------------------------------------------------------------
        cp_burst_type: coverpoint cov_item.burst_type {
            bins incr = {2'b01};
        }

        // -----------------------------------------------------------------
        // Response code
        // -----------------------------------------------------------------
        cp_resp: coverpoint cov_item.resp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
        }

        // -----------------------------------------------------------------
        // Cross: mỗi loại transaction × mọi register
        // Đây là coverage quan trọng nhất:
        // "mọi register phải được cả write lẫn read"
        // -----------------------------------------------------------------
        cx_type_addr: cross cp_txn_type, cp_addr;

        // -----------------------------------------------------------------
        // Cross: mỗi loại transaction × mọi burst length
        // Đảm bảo burst write và burst read đều được test ở mọi độ dài
        // -----------------------------------------------------------------
        cx_type_burst: cross cp_txn_type, cp_burst_len;

    endgroup : axi4_cg

    // =========================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi4_cg = new();
    endfunction

    function void write(axi4_seq_item t);
        cov_item = t;
        axi4_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        real cov = axi4_cg.get_coverage();
        `uvm_info("COV", $sformatf(
            "========================================"), UVM_NONE)
        `uvm_info("COV", $sformatf(
            "  Functional Coverage = %.2f%%", cov), UVM_NONE)
        `uvm_info("COV", $sformatf(
            "  cp_txn_type   = %.2f%%", axi4_cg.cp_txn_type.get_coverage()),   UVM_NONE)
        `uvm_info("COV", $sformatf(
            "  cp_addr       = %.2f%%", axi4_cg.cp_addr.get_coverage()),        UVM_NONE)
        `uvm_info("COV", $sformatf(
            "  cp_burst_len  = %.2f%%", axi4_cg.cp_burst_len.get_coverage()),   UVM_NONE)
        `uvm_info("COV", $sformatf(
            "  cx_type_addr  = %.2f%%", axi4_cg.cx_type_addr.get_coverage()),   UVM_NONE)
        `uvm_info("COV", $sformatf(
            "  cx_type_burst = %.2f%%", axi4_cg.cx_type_burst.get_coverage()),  UVM_NONE)
        `uvm_info("COV", $sformatf(
            "========================================"), UVM_NONE)

        if (cov < 100.0)
            `uvm_warning("COV", $sformatf(
                "Coverage chưa đạt 100%% (%.2f%%) – thêm transactions", cov))
    endfunction

endclass : axi4_coverage

`endif // AXI4_COVERAGE_SV
