// =============================================================================
// Random Test  –  constrained random, targets 100 % functional coverage
// =============================================================================
`ifndef AXI4_RANDOM_TEST_SV
`define AXI4_RANDOM_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import axi4_pkg::*;

// ---------------------------------------------------------------------------
// Coverage-directed sequence: guarantees every coverpoint bin is hit at
// least once before going fully random.
// ---------------------------------------------------------------------------
class axi4_directed_coverage_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_directed_coverage_seq)

    function new(string name = "axi4_directed_coverage_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;

        // ---- Write + Read every register individually ----
        for (int reg_i = 0; reg_i < NUM_REGS; reg_i++) begin
            // Write
            item = axi4_seq_item::type_id::create($sformatf("cov_wr_%0d",reg_i));
            start_item(item);
            if (!item.randomize() with {
                is_write  == 1'b1;
                addr      == BASE_ADDR + reg_i * 4;
                burst_len == 8'd0;
            }) `uvm_fatal("SEQ","Rnd fail")
            finish_item(item);

            // Read
            item = axi4_seq_item::type_id::create($sformatf("cov_rd_%0d",reg_i));
            start_item(item);
            if (!item.randomize() with {
                is_write  == 1'b0;
                addr      == BASE_ADDR + reg_i * 4;
                burst_len == 8'd0;
            }) `uvm_fatal("SEQ","Rnd fail")
            finish_item(item);
        end

        // ---- Burst length 1,2,3 (AWLEN = 1,2,3) for write & read ----
        for (int bl = 1; bl <= 3; bl++) begin
            for (int s = 0; s <= NUM_REGS - 1 - bl; s += (bl+1)) begin
                // Burst write
                item = axi4_seq_item::type_id::create($sformatf("cov_bw_l%0d_s%0d",bl,s));
                start_item(item);
                if (!item.randomize() with {
                    is_write  == 1'b1;
                    addr      == BASE_ADDR + s * 4;
                    burst_len == bl;
                }) `uvm_fatal("SEQ","Rnd fail")
                finish_item(item);

                // Burst read
                item = axi4_seq_item::type_id::create($sformatf("cov_br_l%0d_s%0d",bl,s));
                start_item(item);
                if (!item.randomize() with {
                    is_write  == 1'b0;
                    addr      == BASE_ADDR + s * 4;
                    burst_len == bl;
                }) `uvm_fatal("SEQ","Rnd fail")
                finish_item(item);
            end
        end
    endtask
endclass

// ---------------------------------------------------------------------------
// Random Test
// ---------------------------------------------------------------------------
class axi4_random_test extends uvm_test;
    `uvm_component_utils(axi4_random_test)

    axi4_env env;

    // Number of purely random transactions after directed phase
    int unsigned num_rand_txns = 80;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi4_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_directed_coverage_seq cov_seq;
        axi4_random_seq            rand_seq;

        phase.raise_objection(this);
        `uvm_info("TEST","=== AXI4 Random Test START ===", UVM_NONE)

        // Phase 1: coverage-directed
        cov_seq = axi4_directed_coverage_seq::type_id::create("cov_seq");
        cov_seq.start(env.agent.seqr);

        // Phase 2: fully random stress
        rand_seq = axi4_random_seq::type_id::create("rand_seq");
        rand_seq.num_txns = num_rand_txns;
        rand_seq.start(env.agent.seqr);

        `uvm_info("TEST","=== AXI4 Random Test END ===", UVM_NONE)
        phase.drop_objection(this);
    endtask
endclass : axi4_random_test

`endif
