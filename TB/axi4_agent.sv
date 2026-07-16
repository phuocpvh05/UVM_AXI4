// =============================================================================
// axi4_agent.sv
// Active agent: chứa sequencer, driver, monitor
// Driver   → drives signals lên DUT
// Monitor  → passive observe, broadcast qua analysis port
// Sequencer → điều phối seq_item từ sequence đến driver
// =============================================================================
`ifndef AXI4_AGENT_SV
`define AXI4_AGENT_SV

class axi4_agent extends uvm_agent;
    `uvm_component_utils(axi4_agent)

    axi4_driver                     drv;
    axi4_monitor                    mon;
    uvm_sequencer #(axi4_seq_item)  seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = uvm_sequencer #(axi4_seq_item)::type_id::create("seqr", this);
        drv  = axi4_driver::type_id::create("drv",  this);
        mon  = axi4_monitor::type_id::create("mon", this);
    endfunction

    // -------------------------------------------------------------------------
    // Kết nối sequencer → driver
    // Monitor không cần connect vì dùng analysis port (push model)
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass : axi4_agent

`endif // AXI4_AGENT_SV
