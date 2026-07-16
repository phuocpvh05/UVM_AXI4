// =============================================================================
// axi4_direct_seq.sv
// Deterministic – ghi/đọc từng register, mọi burst length, byte-strobe test
// =============================================================================
`ifndef AXI4_DIRECT_SEQ_SV
`define AXI4_DIRECT_SEQ_SV

class axi4_direct_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_direct_seq)

    function new(string name = "axi4_direct_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;

        // ------------------------------------------------------------------
        // 1. Single write mọi register
        // ------------------------------------------------------------------
        for (int i = 0; i < NUM_REGS; i++) begin
            item = axi4_seq_item::type_id::create($sformatf("sw_%0d", i));
            start_item(item);
            if (!item.randomize() with {
                is_write  == 1'b1;
                addr      == BASE_ADDR + i * 4;
                burst_len == 8'd0;
                data[0]   == (32'hA5A5_0000 | i);
                strb[0]   == 4'hF;
            }) `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end

        // ------------------------------------------------------------------
        // 2. Single read-back mọi register
        // ------------------------------------------------------------------
        for (int i = 0; i < NUM_REGS; i++) begin
            item = axi4_seq_item::type_id::create($sformatf("sr_%0d", i));
            start_item(item);
            if (!item.randomize() with {
                is_write  == 1'b0;
                addr      == BASE_ADDR + i * 4;
                burst_len == 8'd0;
            }) `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end

        // ------------------------------------------------------------------
        // 3. 4-beat burst write tại reg[0..3]
        // ------------------------------------------------------------------
        item = axi4_seq_item::type_id::create("bw4");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b1;
            addr      == BASE_ADDR;
            burst_len == 8'd3;
            data[0]   == 32'hDEAD_BEEF;
            data[1]   == 32'hCAFE_BABE;
            data[2]   == 32'h1234_5678;
            data[3]   == 32'h9ABC_DEF0;
            foreach (strb[i]) strb[i] == 4'hF;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);

        // ------------------------------------------------------------------
        // 4. 4-beat burst read tại reg[0..3]
        // ------------------------------------------------------------------
        item = axi4_seq_item::type_id::create("br4");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b0;
            addr      == BASE_ADDR;
            burst_len == 8'd3;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);

        // ------------------------------------------------------------------
        // 5. Byte-strobe test – chỉ ghi 2 byte cao (WSTRB=4'b1100)
        // ------------------------------------------------------------------
        item = axi4_seq_item::type_id::create("strobe_wr");
        start_item(item);
	item.c_strb.constraint_mode(0);
        if (!item.randomize() with {
            is_write  == 1'b1;
            addr      == BASE_ADDR + 8 * 4;  // reg[8]
            burst_len == 8'd0;
            data[0]   == 32'hFF00_1234;
            strb[0]   == 4'b1100;
        }) `uvm_fatal("SEQ", "Randomize failed")
	item.c_strb.constraint_mode(1);
        finish_item(item);

        // Read-back reg[8] để verify partial write
        item = axi4_seq_item::type_id::create("strobe_rd");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b0;
            addr      == BASE_ADDR + 8 * 4;
            burst_len == 8'd0;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);

        // ------------------------------------------------------------------
        // 6. 2-beat burst write/read tại reg[12..13]
        // ------------------------------------------------------------------
        item = axi4_seq_item::type_id::create("bw2");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b1;
            addr      == BASE_ADDR + 12 * 4;
            burst_len == 8'd1;
            data[0]   == 32'hBBBB_BBBB;
            data[1]   == 32'hCCCC_CCCC;
            strb[0]   == 4'hF;
            strb[1]   == 4'hF;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);

        item = axi4_seq_item::type_id::create("br2");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b0;
            addr      == BASE_ADDR + 12 * 4;
            burst_len == 8'd1;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);

        // ------------------------------------------------------------------
        // 7. 3-beat burst write/read tại reg[4..6]
        // ------------------------------------------------------------------
        item = axi4_seq_item::type_id::create("bw3");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b1;
            addr      == BASE_ADDR + 4 * 4;
            burst_len == 8'd2;
            data[0]   == 32'hAAAA_0001;
            data[1]   == 32'hAAAA_0002;
            data[2]   == 32'hAAAA_0003;
            foreach (strb[i]) strb[i] == 4'hF;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);

        item = axi4_seq_item::type_id::create("br3");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b0;
            addr      == BASE_ADDR + 4 * 4;
            burst_len == 8'd2;
        }) `uvm_fatal("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass : axi4_direct_seq

`endif // AXI4_DIRECT_SEQ_SV
