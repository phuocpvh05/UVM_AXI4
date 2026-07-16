// =============================================================================
// axi4_single_read_seq.sv
// Gửi đúng 1 read transaction, 1 beat (ARLEN=0)
// =============================================================================
`ifndef AXI4_SINGLE_READ_SEQ_SV
`define AXI4_SINGLE_READ_SEQ_SV

class axi4_single_read_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_single_read_seq)

    rand logic [ADDR_WIDTH-1:0] rd_addr;

    constraint c_addr_align {
        rd_addr[1:0] == 2'b00;
        rd_addr >= BASE_ADDR;
        rd_addr <  BASE_ADDR + NUM_REGS * 4;
    }

    function new(string name = "axi4_single_read_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item = axi4_seq_item::type_id::create("single_rd");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b0;
            addr      == rd_addr;
            burst_len == 8'd0;
        }) `uvm_fatal("SEQ", "Randomize failed – axi4_single_read_seq")
        finish_item(item);
    endtask
endclass : axi4_single_read_seq

`endif // AXI4_SINGLE_READ_SEQ_SV
