// =============================================================================
// axi4_single_write_seq.sv
// Gửi đúng 1 write transaction, 1 beat (AWLEN=0)
// =============================================================================
`ifndef AXI4_SINGLE_WRITE_SEQ_SV
`define AXI4_SINGLE_WRITE_SEQ_SV

class axi4_single_write_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_single_write_seq)

    // Cho phép test override trực tiếp
    rand logic [ADDR_WIDTH-1:0] wr_addr;
    rand logic [DATA_WIDTH-1:0] wr_data;

    constraint c_addr_align {
        wr_addr[1:0] == 2'b00;
        wr_addr >= BASE_ADDR;
        wr_addr <  BASE_ADDR + NUM_REGS * 4;
    }

    function new(string name = "axi4_single_write_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item = axi4_seq_item::type_id::create("single_wr");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b1;
            addr      == wr_addr;
            burst_len == 8'd0;
            data[0]   == wr_data;
        }) `uvm_fatal("SEQ", "Randomize failed – axi4_single_write_seq")
        finish_item(item);
    endtask
endclass : axi4_single_write_seq

`endif // AXI4_SINGLE_WRITE_SEQ_SV
