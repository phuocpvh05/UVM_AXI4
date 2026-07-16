// =============================================================================
// axi4_base_seq.sv
// Base sequence – tất cả sequence khác kế thừa từ đây
// =============================================================================
`ifndef AXI4_BASE_SEQ_SV
`define AXI4_BASE_SEQ_SV

class axi4_base_seq extends uvm_sequence #(axi4_seq_item);
    `uvm_object_utils(axi4_base_seq)

    function new(string name = "axi4_base_seq");
        super.new(name);
    endfunction
endclass : axi4_base_seq

`endif // AXI4_BASE_SEQ_SV
