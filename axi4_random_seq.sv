// =============================================================================
// axi4_random_seq.sv
// Fully constrained-random – dùng trong axi4_random_test
// =============================================================================
`ifndef AXI4_RANDOM_SEQ_SV
`define AXI4_RANDOM_SEQ_SV

class axi4_random_seq extends axi4_base_seq;
    `uvm_object_utils(axi4_random_seq)

    int unsigned num_txns = 60;

    function new(string name = "axi4_random_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;
        repeat (num_txns) begin
            item = axi4_seq_item::type_id::create("rand_item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("SEQ", "Randomize failed – axi4_random_seq")
            finish_item(item);
        end
    endtask
endclass : axi4_random_seq

`endif // AXI4_RANDOM_SEQ_SV
