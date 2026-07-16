`ifndef AXI4_DRIVER_SV
`define AXI4_DRIVER_SV

class axi4_driver extends uvm_driver #(axi4_seq_item);
    `uvm_component_utils(axi4_driver)

    virtual axi4_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual axi4_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("DRV", "Cannot get vif")
    endfunction

    // =========================================================================
    // Run phase
    // =========================================================================
    task run_phase(uvm_phase phase);
        axi4_seq_item item;

        // Chờ clocking block hoạt động rồi mới drive tín hiệu.
        @(vif.master_cb);
        reset_signals();

        wait (vif.ARESETn === 1'b1);
        repeat (5) @(vif.master_cb);

        `uvm_info("DRV", "Driver ready", UVM_MEDIUM)

        forever begin
            seq_item_port.get_next_item(item);

            `uvm_info(
                "DRV",
                item.convert2string(),
                UVM_MEDIUM
            )

            if (item.is_write)
                drive_write(item);
            else
                drive_read(item);

            seq_item_port.item_done();
        end
    endtask

    // =========================================================================
    // Reset master outputs
    // =========================================================================
    task reset_signals();
        vif.master_cb.AWVALID <= 1'b0;
        vif.master_cb.AWID    <= '0;
        vif.master_cb.AWADDR  <= '0;
        vif.master_cb.AWLEN   <= '0;
        vif.master_cb.AWSIZE  <= 3'b010;
        vif.master_cb.AWBURST <= 2'b01;

        vif.master_cb.WVALID  <= 1'b0;
        vif.master_cb.WDATA   <= '0;
        vif.master_cb.WSTRB   <= '0;
        vif.master_cb.WLAST   <= 1'b0;

        vif.master_cb.BREADY  <= 1'b0;

        vif.master_cb.ARVALID <= 1'b0;
        vif.master_cb.ARID    <= '0;
        vif.master_cb.ARADDR  <= '0;
        vif.master_cb.ARLEN   <= '0;
        vif.master_cb.ARSIZE  <= 3'b010;
        vif.master_cb.ARBURST <= 2'b01;

        vif.master_cb.RREADY  <= 1'b0;
    endtask

    // =========================================================================
    // Write transaction
    // =========================================================================
    task drive_write(axi4_seq_item item);
        // ---------------------------------------------------------------------
        // Write address channel
        // ---------------------------------------------------------------------
        @(vif.master_cb);

        vif.master_cb.AWID    <= item.id;
        vif.master_cb.AWADDR  <= item.addr;
        vif.master_cb.AWLEN   <= item.burst_len;
        vif.master_cb.AWSIZE  <= item.size;
        vif.master_cb.AWBURST <= item.burst_type;
        vif.master_cb.AWVALID <= 1'b1;

        do begin
            @(vif.master_cb);
        end while (vif.master_cb.AWREADY !== 1'b1);

        vif.master_cb.AWVALID <= 1'b0;

        // ---------------------------------------------------------------------
        // Write data channel
        // ---------------------------------------------------------------------
        for (int beat = 0;
             beat <= item.burst_len;
             beat++) begin

            vif.master_cb.WDATA  <= item.data[beat];
            vif.master_cb.WSTRB  <= item.strb[beat];
            vif.master_cb.WLAST  <=
                (beat == item.burst_len);
            vif.master_cb.WVALID <= 1'b1;

            do begin
                @(vif.master_cb);
            end while (vif.master_cb.WREADY !== 1'b1);
        end

        vif.master_cb.WVALID <= 1'b0;
        vif.master_cb.WLAST  <= 1'b0;
        vif.master_cb.WDATA  <= '0;
        vif.master_cb.WSTRB  <= '0;

        // ---------------------------------------------------------------------
        // Write response channel
        // ---------------------------------------------------------------------
        vif.master_cb.BREADY <= 1'b1;

        do begin
            @(vif.master_cb);
        end while (vif.master_cb.BVALID !== 1'b1);

        item.resp = vif.master_cb.BRESP;

        if (vif.master_cb.BID !== item.id) begin
            `uvm_error("DRV", $sformatf(
                "BID mismatch: GOT=%0d EXP=%0d",
                vif.master_cb.BID,
                item.id
            ))
        end

        if (vif.master_cb.BRESP !== 2'b00) begin
            `uvm_error("DRV", $sformatf(
                "Write response error: addr=0x%08h BRESP=%02b",
                item.addr,
                vif.master_cb.BRESP
            ))
        end

        vif.master_cb.BREADY <= 1'b0;
    endtask

    // =========================================================================
    // Read transaction
    // =========================================================================
    task drive_read(axi4_seq_item item);
        // Đưa RREADY lên cùng lúc với ARVALID.
        // Như vậy driver không bỏ lỡ beat đầu tiên.
        @(vif.master_cb);

        vif.master_cb.RREADY  <= 1'b1;
        vif.master_cb.ARID    <= item.id;
        vif.master_cb.ARADDR  <= item.addr;
        vif.master_cb.ARLEN   <= item.burst_len;
        vif.master_cb.ARSIZE  <= item.size;
        vif.master_cb.ARBURST <= item.burst_type;
        vif.master_cb.ARVALID <= 1'b1;

        // ---------------------------------------------------------------------
        // Read address handshake
        // ---------------------------------------------------------------------
        do begin
            @(vif.master_cb);
        end while (vif.master_cb.ARREADY !== 1'b1);

        vif.master_cb.ARVALID <= 1'b0;

        // ---------------------------------------------------------------------
        // Read data channel
        // ---------------------------------------------------------------------
        for (int beat = 0;
             beat <= item.burst_len;
             beat++) begin

            do begin
                @(vif.master_cb);
            end while (vif.master_cb.RVALID !== 1'b1);

            // Không dùng #1.
            // master_cb input #1step lấy dữ liệu trước khi DUT tăng index.
            item.data[beat] = vif.master_cb.RDATA;
            item.resp       = vif.master_cb.RRESP;

            if (vif.master_cb.RID !== item.id) begin
                `uvm_error("DRV", $sformatf(
                    "RID mismatch beat=%0d: GOT=%0d EXP=%0d",
                    beat,
                    vif.master_cb.RID,
                    item.id
                ))
            end

            if (vif.master_cb.RRESP !== 2'b00) begin
                `uvm_error("DRV", $sformatf(
                    "Read response error beat=%0d addr=0x%08h RRESP=%02b",
                    beat,
                    item.addr,
                    vif.master_cb.RRESP
                ))
            end

            if ((beat < item.burst_len) &&
                (vif.master_cb.RLAST === 1'b1)) begin
                `uvm_error("DRV", $sformatf(
                    "Early RLAST at beat=%0d, ARLEN=%0d",
                    beat,
                    item.burst_len
                ))
            end

            if ((beat == item.burst_len) &&
                (vif.master_cb.RLAST !== 1'b1)) begin
                `uvm_error("DRV", $sformatf(
                    "Missing RLAST at final beat=%0d",
                    beat
                ))
            end
        end

        vif.master_cb.RREADY <= 1'b0;
    endtask

endclass : axi4_driver

`endif // AXI4_DRIVER_SV
