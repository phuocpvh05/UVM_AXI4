// =============================================================================
// axi4_env.sv
// Top-level environment:
//   agent      → driver + monitor + sequencer
//   scoreboard → kiểm tra data correctness
//   coverage   → theo dõi functional coverage
// Connect: monitor.ap → scoreboard.analysis_export
//          monitor.ap → coverage.analysis_export
// =============================================================================
`ifndef AXI4_ENV_SV
`define AXI4_ENV_SV

class axi4_env extends uvm_env;
    `uvm_component_utils(axi4_env)

    axi4_agent      agent;
    axi4_scoreboard sb;
    axi4_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = axi4_agent::type_id::create("agent", this);
        sb    = axi4_scoreboard::type_id::create("sb",  this);
        cov   = axi4_coverage::type_id::create("cov",  this);
    endfunction

    // -------------------------------------------------------------------------
    // Monitor broadcast (TLM analysis port) → scoreboard + coverage
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        agent.mon.ap.connect(sb.analysis_export);
        agent.mon.ap.connect(cov.analysis_export);
    endfunction

endclass : axi4_env

`endif // AXI4_ENV_SV
