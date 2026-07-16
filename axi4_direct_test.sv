`ifndef AXI4_DIRECT_TEST_SV
`define AXI4_DIRECT_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_direct_test extends uvm_test;
    `uvm_component_utils(axi4_direct_test)

    axi4_env env;

    function new(
        string name,
        uvm_component parent
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = axi4_env::type_id::create(
            "env",
            this
        );
    endfunction

    task run_phase(uvm_phase phase);
        axi4_direct_seq seq;

        phase.raise_objection(this);

        `uvm_info(
            "TEST",
            "=== AXI4 Direct Test START ===",
            UVM_NONE
        )

        seq = axi4_direct_seq::type_id::create(
            "direct_seq"
        );

        seq.start(env.agent.seqr);

        // ---------------------------------------------------------------------
        // Kiểm tra burst có 1, 2 và 3 beats.
        //
        // Quy ước AXI:
        //   num_beats = 1 -> AxLEN = 0
        //   num_beats = 2 -> AxLEN = 1
        //   num_beats = 3 -> AxLEN = 2
        // ---------------------------------------------------------------------
        begin
            axi4_burst_write_seq bw;
            axi4_burst_read_seq  br;

            for (int beats = 1;
                 beats <= 3;
                 beats++) begin

                logic [ADDR_WIDTH-1:0] burst_addr;

                burst_addr =
                    BASE_ADDR + (4 - beats) * 4;

                bw = axi4_burst_write_seq::type_id::create(
                    $sformatf("bw_%0d_beats", beats)
                );

                br = axi4_burst_read_seq::type_id::create(
                    $sformatf("br_%0d_beats", beats)
                );

                if (!bw.randomize() with {
                    num_beats  == beats;
                    start_addr == burst_addr;
                }) begin
                    `uvm_fatal(
                        "TEST",
                        "Burst write randomize failed"
                    )
                end

                if (!br.randomize() with {
                    num_beats  == beats;
                    start_addr == burst_addr;
                }) begin
                    `uvm_fatal(
                        "TEST",
                        "Burst read randomize failed"
                    )
                end

                bw.start(env.agent.seqr);
                br.start(env.agent.seqr);
            end
        end

        // Cho monitor/scoreboard thêm vài clock để hoàn tất transaction cuối.
        repeat (5) @(env.agent.drv.vif.master_cb);

        `uvm_info(
            "TEST",
            "=== AXI4 Direct Test END ===",
            UVM_NONE
        )

        phase.drop_objection(this);
    endtask

endclass : axi4_direct_test

`endif // AXI4_DIRECT_TEST_SV
