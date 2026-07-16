// =============================================================================
// axi4_burst_read_seq.sv
// Burst INCR read – 1 đến 4 beats
// =============================================================================
`ifndef AXI4_BURST_READ_SEQ_SV
`define AXI4_BURST_READ_SEQ_SV

class axi4_burst_read_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_burst_read_seq)

    rand logic [ADDR_WIDTH-1:0] start_addr;
    rand logic [7:0]            num_beats;

    constraint c_beats   { num_beats inside {[1:4]}; }
    constraint c_addr_ok {
        start_addr[1:0] == 2'b00;
        start_addr >= BASE_ADDR;
        (start_addr + (num_beats - 1) * 4) < BASE_ADDR + NUM_REGS * 4;
    }

    function new(string name = "axi4_burst_read_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item = axi4_seq_item::type_id::create("burst_rd");
        start_item(item);
        if (!item.randomize() with {
            is_write  == 1'b0;
            addr      == start_addr;
            burst_len == num_beats - 1;
        }) `uvm_fatal("SEQ", "Randomize failed – axi4_burst_read_seq")
        finish_item(item);
    endtask
endclass : axi4_burst_read_seq

`endif // AXI4_BURST_READ_SEQ_SV
