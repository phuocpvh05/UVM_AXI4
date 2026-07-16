// =============================================================================
// AXI4 Full Slave – 16 x 32-bit Register Bank
// Read FSM: combinational RDATA, rd_cur_idx update sequential
// Driver/Monitor phải dùng clocking block với input #1step để sample đúng
// =============================================================================
module axi4_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter NUM_REGS   = 16,
    parameter ID_WIDTH   = 4
)(
    input  logic                    ACLK,
    input  logic                    ARESETn,
    input  logic [ID_WIDTH-1:0]     AWID,
    input  logic [ADDR_WIDTH-1:0]   AWADDR,
    input  logic [7:0]              AWLEN,
    input  logic [2:0]              AWSIZE,
    input  logic [1:0]              AWBURST,
    input  logic                    AWVALID,
    output logic                    AWREADY,
    input  logic [DATA_WIDTH-1:0]   WDATA,
    input  logic [DATA_WIDTH/8-1:0] WSTRB,
    input  logic                    WLAST,
    input  logic                    WVALID,
    output logic                    WREADY,
    output logic [ID_WIDTH-1:0]     BID,
    output logic [1:0]              BRESP,
    output logic                    BVALID,
    input  logic                    BREADY,
    input  logic [ID_WIDTH-1:0]     ARID,
    input  logic [ADDR_WIDTH-1:0]   ARADDR,
    input  logic [7:0]              ARLEN,
    input  logic [2:0]              ARSIZE,
    input  logic [1:0]              ARBURST,
    input  logic                    ARVALID,
    output logic                    ARREADY,
    output logic [ID_WIDTH-1:0]     RID,
    output logic [DATA_WIDTH-1:0]   RDATA,
    output logic [1:0]              RRESP,
    output logic                    RLAST,
    output logic                    RVALID,
    input  logic                    RREADY
);

    localparam REG_ADDR_BITS = 4;

    logic [DATA_WIDTH-1:0] reg_bank [0:NUM_REGS-1];

    // =========================================================================
    // Write FSM
    // =========================================================================
    typedef enum logic [1:0] {WR_IDLE, WR_DATA, WR_RESP} wr_state_t;
    wr_state_t wr_state;

    logic [ID_WIDTH-1:0]   aw_id_r;
    logic [ADDR_WIDTH-1:0] wr_cur_addr;
    logic [3:0]            wr_idx;

    always_comb wr_idx = wr_cur_addr[REG_ADDR_BITS+1:2];

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wr_state    <= WR_IDLE;
            AWREADY     <= 1'b1;
            WREADY      <= 1'b0;
            BVALID      <= 1'b0;
            BID         <= '0;
            BRESP       <= 2'b00;
            aw_id_r     <= '0;
            wr_cur_addr <= '0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    BVALID <= 1'b0;
                    if (AWVALID && AWREADY) begin
                        aw_id_r     <= AWID;
                        wr_cur_addr <= AWADDR;
                        AWREADY     <= 1'b0;
                        WREADY      <= 1'b1;
                        wr_state    <= WR_DATA;
                    end
                end
                WR_DATA: begin
                    if (WVALID && WREADY) begin
                        for (int b = 0; b < DATA_WIDTH/8; b++)
                            if (WSTRB[b])
                                reg_bank[wr_idx][b*8 +: 8] <= WDATA[b*8 +: 8];
                        wr_cur_addr <= wr_cur_addr + 4;
                        if (WLAST) begin
                            WREADY   <= 1'b0;
                            BVALID   <= 1'b1;
                            BID      <= aw_id_r;
                            BRESP    <= 2'b00;
                            wr_state <= WR_RESP;
                        end
                    end
                end
                WR_RESP: begin
                    if (BVALID && BREADY) begin
                        BVALID   <= 1'b0;
                        AWREADY  <= 1'b1;
                        wr_state <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // =========================================================================
    // Read FSM
    //
    // RDATA = combinational từ rd_cur_idx
    // rd_cur_idx update sequential: tăng NGAY KHI handshake
    //
    // Clocking block input #1step sample TRƯỚC posedge
    // → tại thời điểm sample, rd_cur_idx chưa tăng
    // → RDATA = reg_bank[rd_cur_idx_cũ] = đúng beat hiện tại ✓
    //
    // Ví dụ ARLEN=2 (3 beats), ARADDR=0x10 (base_idx=4):
    //   RD_IDLE: rd_cur_idx<=4, RVALID<=1, RLAST<=(2==0)=0
    //   -- posedge T1: rd_cur_idx=4, RDATA=reg[4] --
    //   CB sample T1 (#1step trước T1): RDATA=reg[4] ← beat0 ✓
    //   handshake T1: rd_cur_idx<=5, RLAST<=(0+1==2)=0, rd_beat_cnt<=1
    //   -- posedge T2: rd_cur_idx=5, RDATA=reg[5] --
    //   CB sample T2: RDATA=reg[5] ← beat1 ✓
    //   handshake T2: rd_cur_idx<=6, RLAST<=(1+1==2)=1
    //   -- posedge T3: rd_cur_idx=6, RDATA=reg[6], RLAST=1 --
    //   CB sample T3: RDATA=reg[6] ← beat2 ✓, RLAST=1 → done
    // =========================================================================
    typedef enum logic [1:0] {RD_IDLE, RD_DATA} rd_state_t;
    rd_state_t rd_state;

    logic [ID_WIDTH-1:0]  ar_id_r;
    logic [7:0]           ar_len_r;
    logic [7:0]           rd_beat_cnt;
    logic [3:0]           rd_cur_idx;

    // Combinational read – RDATA phản ánh ngay rd_cur_idx
    assign RDATA = reg_bank[rd_cur_idx];

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rd_state    <= RD_IDLE;
            ARREADY     <= 1'b1;
            RVALID      <= 1'b0;
            RLAST       <= 1'b0;
            RID         <= '0;
            RRESP       <= 2'b00;
            ar_id_r     <= '0;
            ar_len_r    <= '0;
            rd_beat_cnt <= '0;
            rd_cur_idx  <= '0;
        end else begin
            case (rd_state)

                RD_IDLE: begin
                    RVALID <= 1'b0;
                    if (ARVALID && ARREADY) begin
                        ar_id_r     <= ARID;
                        ar_len_r    <= ARLEN;
                        rd_beat_cnt <= '0;
                        ARREADY     <= 1'b0;
                        RID         <= ARID;
                        RRESP       <= 2'b00;
                        rd_cur_idx  <= ARADDR[REG_ADDR_BITS+1:2];
                        RLAST       <= (ARLEN == 8'd0);
                        RVALID      <= 1'b1;
                        rd_state    <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    if (RVALID && RREADY) begin
                        if (RLAST) begin
                            RVALID   <= 1'b0;
                            RLAST    <= 1'b0;
                            ARREADY  <= 1'b1;
                            rd_state <= RD_IDLE;
                        end else begin
                            rd_beat_cnt <= rd_beat_cnt + 1;
                            rd_cur_idx  <= rd_cur_idx + 1;
                            RID         <= ar_id_r;
                            RRESP       <= 2'b00;
                            RLAST       <= (rd_beat_cnt + 1 == ar_len_r);
                        end
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // =========================================================================
    // Reset register bank
    // =========================================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            for (int i = 0; i < NUM_REGS; i++)
                reg_bank[i] <= 32'hDEAD_0000 | i;
    end

endmodule
