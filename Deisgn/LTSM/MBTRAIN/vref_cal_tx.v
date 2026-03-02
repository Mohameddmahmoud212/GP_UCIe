module vref_cal_tx (
    //inputs
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,// from mbtrain_controller: enables this VREF-CAL block

    // 0: VALVREF, 1: DATAVREF, 2: VALTRAINVREF, 3: DATATRAINVREF
    // MBTRAIN substate selector (used ONLY for ack routing)
    input              i_mainband_or_valtrain_test,// from mbtrain_controller

    // sideband decoded RX
    input  wire [3:0]  i_decoded_sideband_message,// from sideband decoder (msg-number)
    input  wire        i_sideband_valid,  // from sideband decoder: message is valid 
    // it only protect the code from samle a garbage value of the i_decoded_sideband_message 
    // so we depend on both the input decoded msg and only when valid == 1

    // arbitration / handshake
    input  wire        i_busy_negedge_detected, // from sideband interface: "packet sent" indication
    input  wire        i_valid_rx, // from wrapper mux arbitration: RX path is currently valid/high-priority

     // =========================================================================
    // Point-test / algo status (from point-test block local to THIS die)
    // In the thesis VREF-CAL performs a point test between the start and end handshakes. :contentReference[oaicite:5]{index=5}
    // =========================================================================
    input  wire        i_algo_done_ack,       // from point-test/algo: done
    input  wire [15:0] i_rx_lanes_result,     // from point-test: per-lane pass bitmap

    // =========================================================================
    // Outputs to sideband TX (to wrapper mux -> sideband encoder/iface)
    // =========================================================================
    output reg  [3:0]  o_sideband_message, // to sideband encoder: msg-number only
    output reg         o_valid_tx,         // to wrapper mux: asserts when we drive o_sideband_message

    // =========================================================================
    // Outputs to Point-Test block (pattern generation / enable)
    // =========================================================================
    output reg         o_pt_en,                     // to point-test: enable while CAL_ALGO
    output reg         o_mainband_or_valtrain_test, // to point-test: 0=mainband, 1=val-pattern

    // =========================================================================
    // ACKs back to MBTRAIN_CONTROLLER (which state to advance)
    // =========================================================================
    output reg         o_vref_ack,        // to mbtrain_controller
    

    // =========================================================================
    // Status/debug (to status regs / scoreboard)
    // =========================================================================
    output reg         o_vref_fail,      // fail if all lanes failed (placeholder policy)
    output reg [15:0]  o_vref_lane_mask  // last captured lane results
);
    // -------------------------------------------------------------------------
    // Message numbers (INIT_REQ/RESP/END_REQ/RESP)
    // -------------------------------------------------------------------------
    localparam [3:0] MSGNUM_START_REQ = 4'd1;
    localparam [3:0] MSGNUM_START_RSP = 4'd2;
    localparam [3:0] MSGNUM_END_REQ   = 4'd3;
    localparam [3:0] MSGNUM_END_RSP   = 4'd4;

    // -------------------------------------------------------------------------
    // FSM states (PDF TX flow): IDLE -> START_REQ -> CAL_ALGO -> END_REQ -> FINISH
    // -------------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE        = 3'd0,
        ST_START_REQ   = 3'd1,
        ST_CAL_ALGO    = 3'd2,
        ST_END_REQ     = 3'd3,
        ST_TEST_FINISH = 3'd4;

    reg [2:0] cs, ns;

    // -------------------------------------------------------------------------
    // state register
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= ST_IDLE;
        else        cs <= ns;
    end

    // -------------------------------------------------------------------------
    // next-state logic
    // -------------------------------------------------------------------------
    always @(*) begin
        ns = cs;
        case (cs)
            ST_IDLE: begin
                if (i_en) ns = ST_START_REQ;
            end

            ST_START_REQ: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_START_RSP))
                    ns = ST_CAL_ALGO;
            end

            ST_CAL_ALGO: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_algo_done_ack)
                    ns = ST_END_REQ;
            end

            ST_END_REQ: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_END_RSP))
                    ns = ST_TEST_FINISH;
            end

            ST_TEST_FINISH: begin
                if (!i_en) ns = ST_IDLE;
            end

            default: ns = ST_IDLE;
        endcase
    end

    // -------------------------------------------------------------------------
    // registered outputs
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message          <= 4'd0;
            o_valid_tx                  <= 1'b0;

            o_pt_en                     <= 1'b0;
            o_mainband_or_valtrain_test <= 1'b0;

            o_vref_ack                  <= 1'b0;
            o_vref_fail                 <= 1'b0;
            o_vref_lane_mask            <= 16'h0000;
        end else begin
            // clear acks when disabled
            if (!i_en) begin
                o_vref_ack       <= 1'b0;
            end

            case (cs)
                ST_IDLE: begin
                    o_valid_tx <= 1'b0;
                    o_pt_en    <= 1'b0;
                    o_mainband_or_valtrain_test <= 1'b0;
                    o_sideband_message <= 4'd0;

                    if (ns == ST_START_REQ) begin
                        // new run
                        o_vref_fail      <= 1'b0;
                        o_vref_lane_mask <= 16'h0000;

                        // issue START_REQ (INIT_REQ)
                        o_sideband_message <= MSGNUM_START_REQ;
                        o_valid_tx         <= 1'b1;
                    end
                end

                ST_START_REQ: begin
                    o_sideband_message <= MSGNUM_START_REQ;

                    // drop valid when interface indicates sent
                    if (i_busy_negedge_detected && ~i_valid_rx)
                        o_valid_tx <= 1'b0;

                    // when START_RSP received -> next state will enable PT
                end

                ST_CAL_ALGO: begin
                    o_valid_tx <= 1'b0;
                    o_pt_en    <= 1'b1;
                    o_mainband_or_valtrain_test <= i_mainband_or_valtrain_test;

                    if (ns == ST_END_REQ) begin
                        o_pt_en <= 1'b0;

                        o_vref_lane_mask <= i_rx_lanes_result;
                        o_vref_fail      <= (i_rx_lanes_result == 16'h0000);

                        o_sideband_message <= MSGNUM_END_REQ;
                        o_valid_tx         <= 1'b1;
                    end
                end

                ST_END_REQ: begin
                    o_sideband_message <= MSGNUM_END_REQ;

                    if (i_busy_negedge_detected && ~i_valid_rx)
                        o_valid_tx <= 1'b0;

                    if (ns == ST_TEST_FINISH) begin
                        o_sideband_message <= 4'd0;

                        // raise only matching ack
                        o_vref_ack       <= 1'b1;
                    end
                end

                ST_TEST_FINISH: begin
                    o_valid_tx <= 1'b0;
                    o_pt_en    <= 1'b0;
                    // keep ACKs until i_en drops
                end

                default: ;
            endcase
        end
    end

endmodule
