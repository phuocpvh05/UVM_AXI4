`ifndef AXI4_SEQ_ITEM_SV
`define AXI4_SEQ_ITEM_SV

class axi4_seq_item extends uvm_sequence_item;

    // ── Fields phải declare TRƯỚC uvm_object_utils_begin ──
    rand logic [3:0]  id;
    rand logic [31:0] addr;
    rand logic [7:0]  burst_len;
    rand logic [1:0]  burst_type;
    rand logic [2:0]  size;
    rand logic        is_write;

    rand logic [31:0] data [16];
    rand logic [3:0]  strb [16];

    logic [1:0] resp;

    // ── Sau đó mới dùng macro ──
    `uvm_object_utils_begin(axi4_seq_item)
        `uvm_field_int(id,          UVM_ALL_ON)
        `uvm_field_int(addr,        UVM_ALL_ON)
        `uvm_field_int(burst_len,   UVM_ALL_ON)
        `uvm_field_int(burst_type,  UVM_ALL_ON)
        `uvm_field_int(size,        UVM_ALL_ON)
        `uvm_field_int(is_write,    UVM_ALL_ON)
        `uvm_field_sarray_int(data, UVM_ALL_ON)
        `uvm_field_sarray_int(strb, UVM_ALL_ON)
        `uvm_field_int(resp,        UVM_ALL_ON)
    `uvm_object_utils_end

    constraint c_addr {
        addr[1:0] == 2'b00;
        addr >= 32'h0000_0000;
        addr <  32'h0000_0000 + 16 * 4;
    }
    constraint c_burst_len {
        burst_len inside {[0:3]};
        (addr + (burst_len * 4)) < 32'h0000_0000 + 16 * 4;
    }
    constraint c_burst_type { burst_type == 2'b01; }
    constraint c_size       { size       == 3'b010; }
    constraint c_strb       { foreach (strb[i]) strb[i] == 4'hF; }
    constraint c_id         { id inside {[0:15]}; }

    function new(string name = "axi4_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s id=%0h addr=%0h len=%0d wr=%0b",
                         get_name(), id, addr, burst_len, is_write);
    endfunction

endclass : axi4_seq_item

`endif
