`ifndef AXI4_MONITOR_SV
`define AXI4_MONITOR_SV

class axi4_monitor extends uvm_monitor;
    `uvm_component_utils(axi4_monitor)

    virtual axi4_if vif;

    uvm_analysis_port #(axi4_seq_item) ap;

    function new(
        string name,
        uvm_component parent
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db #(virtual axi4_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("MON", "Cannot get vif")
    endfunction

    // =========================================================================
    // Run phase
    // =========================================================================
    task run_phase(uvm_phase phase);
        @(vif.monitor_cb);
        wait (vif.ARESETn === 1'b1);

        fork
            monitor_write();
            monitor_read();
        join
    endtask

    // =========================================================================
    // Write monitor
    // =========================================================================
    task monitor_write();
        axi4_seq_item item;

        forever begin
            // -----------------------------------------------------------------
            // AW handshake
            // -----------------------------------------------------------------
            do begin
                @(vif.monitor_cb);
            end while (!(vif.monitor_cb.AWVALID &&
                         vif.monitor_cb.AWREADY));

            item = axi4_seq_item::type_id::create(
                "mon_wr",
                this
            );

            item.is_write   = 1'b1;
            item.id         = vif.monitor_cb.AWID;
            item.addr       = vif.monitor_cb.AWADDR;
            item.burst_len  = vif.monitor_cb.AWLEN;
            item.size       = vif.monitor_cb.AWSIZE;
            item.burst_type = vif.monitor_cb.AWBURST;

            `uvm_info("MON", $sformatf(
                "AW captured: id=%0h addr=0x%08h len=%0d",
                item.id,
                item.addr,
                item.burst_len
            ), UVM_HIGH)

            // -----------------------------------------------------------------
            // W handshakes
            // -----------------------------------------------------------------
            for (int beat = 0;
                 beat <= item.burst_len;
                 beat++) begin

                do begin
                    @(vif.monitor_cb);
                end while (!(vif.monitor_cb.WVALID &&
                             vif.monitor_cb.WREADY));

                item.data[beat] =
                    vif.monitor_cb.WDATA;

                item.strb[beat] =
                    vif.monitor_cb.WSTRB;

                if (beat < item.burst_len) begin
                    if (vif.monitor_cb.WLAST === 1'b1) begin
                        `uvm_error("MON", $sformatf(
                            "Early WLAST: beat=%0d AWLEN=%0d",
                            beat,
                            item.burst_len
                        ))
                    end
                end else begin
                    if (vif.monitor_cb.WLAST !== 1'b1) begin
                        `uvm_error("MON", $sformatf(
                            "Missing WLAST: final beat=%0d AWLEN=%0d",
                            beat,
                            item.burst_len
                        ))
                    end
                end

                `uvm_info("MON", $sformatf(
                    "W captured: beat=%0d/%0d data=0x%08h strb=0x%0h last=%0b",
                    beat,
                    item.burst_len,
                    item.data[beat],
                    item.strb[beat],
                    vif.monitor_cb.WLAST
                ), UVM_HIGH)
            end

            // -----------------------------------------------------------------
            // B handshake
            // -----------------------------------------------------------------
            do begin
                @(vif.monitor_cb);
            end while (!(vif.monitor_cb.BVALID &&
                         vif.monitor_cb.BREADY));

            item.resp = vif.monitor_cb.BRESP;

            if (vif.monitor_cb.BID !== item.id) begin
                `uvm_error("MON", $sformatf(
                    "BID mismatch: GOT=%0h EXP=%0h",
                    vif.monitor_cb.BID,
                    item.id
                ))
            end

            `uvm_info("MON", $sformatf(
                "WRITE complete: id=%0h addr=0x%08h len=%0d resp=%02b",
                item.id,
                item.addr,
                item.burst_len,
                item.resp
            ), UVM_HIGH)

            ap.write(item);
        end
    endtask

    // =========================================================================
    // Read monitor
    // =========================================================================
    task monitor_read();
        axi4_seq_item item;

        forever begin
            // -----------------------------------------------------------------
            // AR handshake
            // -----------------------------------------------------------------
            do begin
                @(vif.monitor_cb);
            end while (!(vif.monitor_cb.ARVALID &&
                         vif.monitor_cb.ARREADY));

            item = axi4_seq_item::type_id::create(
                "mon_rd",
                this
            );

            item.is_write   = 1'b0;
            item.id         = vif.monitor_cb.ARID;
            item.addr       = vif.monitor_cb.ARADDR;
            item.burst_len  = vif.monitor_cb.ARLEN;
            item.size       = vif.monitor_cb.ARSIZE;
            item.burst_type = vif.monitor_cb.ARBURST;

            `uvm_info("MON", $sformatf(
                "AR captured: id=%0h addr=0x%08h len=%0d",
                item.id,
                item.addr,
                item.burst_len
            ), UVM_HIGH)

            // -----------------------------------------------------------------
            // R handshakes
            // -----------------------------------------------------------------
            for (int beat = 0;
                 beat <= item.burst_len;
                 beat++) begin

                do begin
                    @(vif.monitor_cb);
                end while (!(vif.monitor_cb.RVALID &&
                             vif.monitor_cb.RREADY));

                item.data[beat] =
                    vif.monitor_cb.RDATA;

                item.resp =
                    vif.monitor_cb.RRESP;

                if (vif.monitor_cb.RID !== item.id) begin
                    `uvm_error("MON", $sformatf(
                        "RID mismatch beat=%0d: GOT=%0h EXP=%0h",
                        beat,
                        vif.monitor_cb.RID,
                        item.id
                    ))
                end

                if (beat < item.burst_len) begin
                    if (vif.monitor_cb.RLAST === 1'b1) begin
                        `uvm_error("MON", $sformatf(
                            "Early RLAST: beat=%0d ARLEN=%0d",
                            beat,
                            item.burst_len
                        ))
                    end
                end else begin
                    if (vif.monitor_cb.RLAST !== 1'b1) begin
                        `uvm_error("MON", $sformatf(
                            "Missing RLAST: final beat=%0d ARLEN=%0d",
                            beat,
                            item.burst_len
                        ))
                    end
                end

                `uvm_info("MON", $sformatf(
                    "R captured: beat=%0d/%0d data=0x%08h last=%0b",
                    beat,
                    item.burst_len,
                    item.data[beat],
                    vif.monitor_cb.RLAST
                ), UVM_HIGH)
            end

            `uvm_info("MON", $sformatf(
                "READ complete: id=%0h addr=0x%08h len=%0d resp=%02b",
                item.id,
                item.addr,
                item.burst_len,
                item.resp
            ), UVM_HIGH)

            ap.write(item);
        end
    endtask

endclass : axi4_monitor

`endif // AXI4_MONITOR_SV
