`ifndef AXI4_SCOREBOARD_SV
`define AXI4_SCOREBOARD_SV

class axi4_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4_scoreboard)

    uvm_analysis_imp #(
        axi4_seq_item,
        axi4_scoreboard
    ) analysis_export;

    // Reference model của register bank trong DUT.
    logic [DATA_WIDTH-1:0]
        ref_model [0:NUM_REGS-1];

    int unsigned pass_cnt;
    int unsigned fail_cnt;
    int unsigned write_cnt;
    int unsigned read_cnt;

    function new(
        string name,
        uvm_component parent
    );
        super.new(name, parent);
    endfunction

    // =========================================================================
    // Build phase
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_export =
            new("analysis_export", this);

        for (int i = 0; i < NUM_REGS; i++)
            ref_model[i] =
                32'hDEAD_0000 | i;

        pass_cnt  = 0;
        fail_cnt  = 0;
        write_cnt = 0;
        read_cnt  = 0;
    endfunction

    // =========================================================================
    // Validate transaction against current DUT capability
    // =========================================================================
    function bit transaction_is_valid(
        axi4_seq_item item
    );
        longint unsigned first_reg;
        longint unsigned last_reg;

        // DUT hiện chỉ hỗ trợ transfer 4 byte.
        if (item.size != 3'b010) begin
            `uvm_error("SB", $sformatf(
                "Unsupported transfer size: SIZE=%0d. DUT supports SIZE=2 only",
                item.size
            ))
            fail_cnt++;
            return 1'b0;
        end

        // DUT hiện chỉ hỗ trợ INCR burst.
        if (item.burst_type != 2'b01) begin
            `uvm_error("SB", $sformatf(
                "Unsupported burst type: BURST=%02b. DUT supports INCR only",
                item.burst_type
            ))
            fail_cnt++;
            return 1'b0;
        end

        if (item.addr < BASE_ADDR) begin
            `uvm_error("SB", $sformatf(
                "Address below BASE_ADDR: ADDR=0x%08h BASE=0x%08h",
                item.addr,
                BASE_ADDR
            ))
            fail_cnt++;
            return 1'b0;
        end

        if (item.addr[1:0] != 2'b00) begin
            `uvm_error("SB", $sformatf(
                "Unaligned address: ADDR=0x%08h",
                item.addr
            ))
            fail_cnt++;
            return 1'b0;
        end

        first_reg =
            (item.addr - BASE_ADDR) >> 2;

        last_reg =
            first_reg + item.burst_len;

        if (first_reg >= NUM_REGS ||
            last_reg  >= NUM_REGS) begin
            `uvm_error("SB", $sformatf(
                "Transaction out of range: first_reg=%0d last_reg=%0d max_reg=%0d",
                first_reg,
                last_reg,
                NUM_REGS - 1
            ))
            fail_cnt++;
            return 1'b0;
        end

        return 1'b1;
    endfunction

    // =========================================================================
    // Receive transaction from monitor
    // =========================================================================
    function void write(axi4_seq_item item);
        int unsigned base_reg;

        if (!transaction_is_valid(item))
            return;

        base_reg =
            (item.addr - BASE_ADDR) >> 2;

        if (item.is_write) begin
            write_cnt++;
            update_ref_model(item, base_reg);
        end else begin
            read_cnt++;
            check_read_data(item, base_reg);
        end
    endfunction

    // =========================================================================
    // Update reference model
    // =========================================================================
    function void update_ref_model(
        axi4_seq_item item,
        int unsigned base_reg
    );
        if (item.resp !== 2'b00) begin
            `uvm_error("SB", $sformatf(
                "WRITE addr=0x%08h returned BRESP=%02b",
                item.addr,
                item.resp
            ))
            fail_cnt++;
            return;
        end

        for (int beat = 0;
             beat <= item.burst_len;
             beat++) begin

            int unsigned reg_idx;

            reg_idx = base_reg + beat;

            for (int byte_idx = 0;
                 byte_idx < DATA_WIDTH/8;
                 byte_idx++) begin

                if (item.strb[beat][byte_idx]) begin
                    ref_model[reg_idx]
                        [byte_idx*8 +: 8] =
                    item.data[beat]
                        [byte_idx*8 +: 8];
                end
            end

            `uvm_info("SB", $sformatf(
                "MODEL UPDATE reg[%0d]=0x%08h strb=0x%0h",
                reg_idx,
                ref_model[reg_idx],
                item.strb[beat]
            ), UVM_HIGH)
        end
    endfunction

    // =========================================================================
    // Check read data
    // =========================================================================
    function void check_read_data(
        axi4_seq_item item,
        int unsigned base_reg
    );
        if (item.resp !== 2'b00) begin
            `uvm_error("SB", $sformatf(
                "READ addr=0x%08h returned RRESP=%02b",
                item.addr,
                item.resp
            ))
            fail_cnt++;
            return;
        end

        for (int beat = 0;
             beat <= item.burst_len;
             beat++) begin

            int unsigned reg_idx;
            logic [ADDR_WIDTH-1:0] beat_addr;

            reg_idx =
                base_reg + beat;

            beat_addr =
                item.addr + beat * 4;

            if (item.data[beat] !==
                ref_model[reg_idx]) begin

                `uvm_error("SB", $sformatf(
                    "MISMATCH beat=%0d reg[%0d] addr=0x%08h GOT=0x%08h EXP=0x%08h",
                    beat,
                    reg_idx,
                    beat_addr,
                    item.data[beat],
                    ref_model[reg_idx]
                ))

                fail_cnt++;
            end else begin
                `uvm_info("SB", $sformatf(
                    "MATCH beat=%0d reg[%0d] addr=0x%08h data=0x%08h",
                    beat,
                    reg_idx,
                    beat_addr,
                    item.data[beat]
                ), UVM_HIGH)

                pass_cnt++;
            end
        end
    endfunction

    // =========================================================================
    // Report phase
    // =========================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SB",
            "========================================",
            UVM_NONE)

        `uvm_info("SB", $sformatf(
            "Transactions: WRITE=%0d READ=%0d",
            write_cnt,
            read_cnt
        ), UVM_NONE)

        `uvm_info("SB", $sformatf(
            "Scoreboard: PASS=%0d FAIL=%0d",
            pass_cnt,
            fail_cnt
        ), UVM_NONE)

        `uvm_info("SB",
            "========================================",
            UVM_NONE)

        if (fail_cnt > 0) begin
            `uvm_error(
                "SB",
                "TEST FAILED - errors or mismatches detected"
            )
        end else if (pass_cnt == 0) begin
            `uvm_warning(
                "SB",
                "No read data checked"
            )
        end else begin
            `uvm_info(
                "SB",
                "TEST PASSED - all reads match reference model",
                UVM_NONE
            )
        end
    endfunction

endclass : axi4_scoreboard

`endif // AXI4_SCOREBOARD_SV
