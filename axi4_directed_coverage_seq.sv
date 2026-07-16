// =============================================================================
// axi4_directed_coverage_seq.sv
// Đảm bảo mọi coverage bin được hit ít nhất 1 lần trước khi random
// =============================================================================
`ifndef AXI4_DIRECTED_COVERAGE_SEQ_SV
`define AXI4_DIRECTED_COVERAGE_SEQ_SV

class axi4_directed_coverage_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_directed_coverage_seq)

    function new(string name = "axi4_directed_coverage_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;

        // ------------------------------------------------------------------
        // Write + Read từng register (hit cp_addr × cp_txn_type cross)
        // ------------------------------------------------------------------
        for (int reg_i = 0; reg_i < NUM_REGS; reg_i++) begin
            item = axi4_seq_item::type_id::create($sformatf("cov_wr_%0d", reg_i));
            start_item(item);
            if (!item.randomize() with {
                is_write  == 1'b1;
                addr      == BASE_ADDR + reg_i * 4;
                burst_len == 8'd0;
            }) `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);

            item = axi4_seq_item::type_id::create($sformatf("cov_rd_%0d", reg_i));
            start_item(item);
            if (!item.randomize() with {
                is_write  == 1'b0;
                addr      == BASE_ADDR + reg_i * 4;
                burst_len == 8'd0;
            }) `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end

        // ------------------------------------------------------------------
        // Burst len 1/2/3 cho Write & Read (hit cx_type_burst cross)
        // ------------------------------------------------------------------
        for (int bl = 1; bl <= 3; bl++) begin
            // Tìm start address đảm bảo burst không ra ngoài
            for (int s = 0; s <= NUM_REGS - 1 - bl; s += (bl + 1)) begin
                item = axi4_seq_item::type_id::create($sformatf("cov_bw_l%0d_s%0d", bl, s));
                start_item(item);
                if (!item.randomize() with {
                    is_write  == 1'b1;
                    addr      == BASE_ADDR + s * 4;
                    burst_len == bl;
                }) `uvm_fatal("SEQ", "Randomize failed")
                finish_item(item);

                item = axi4_seq_item::type_id::create($sformatf("cov_br_l%0d_s%0d", bl, s));
                start_item(item);
                if (!item.randomize() with {
                    is_write  == 1'b0;
                    addr      == BASE_ADDR + s * 4;
                    burst_len == bl;
                }) `uvm_fatal("SEQ", "Randomize failed")
                finish_item(item);
            end
        end
    endtask
endclass : axi4_directed_coverage_seq

`endif // AXI4_DIRECTED_COVERAGE_SEQ_SV
