module vref_cal_rx (
    // inputs
    input  wire        clk,
    input  wire        rst_n,
    // =========================================================================
    // Enable from MBTRAIN_CONTROLLER
    // =========================================================================
    input  wire        i_en,   // from mbtrain_controller

    // =========================================================================
    // MBTRAIN substate selector (used ONLY for ack routing)
    // =========================================================================
    input              i_mainband_or_valtrain_test, // from mbtrain_controller

    // =========================================================================
    // Sideband decoded RX (from sideband decoder on THIS die)
    // message number only; state/substate carried/filtered outside. :contentReference[oaicite:8]{index=8}
    // =========================================================================
    input  wire [3:0]  i_decoded_sideband_message, // from sideband decoder (msg-number)
    input  wire        i_sideband_valid,            // from sideband decoder

    // =========================================================================
    // Sideband arbitration handshakes (from wrapper/mux + sideband iface)
    // =========================================================================
    input  wire        i_busy_negedge_detected, // from sideband iface: indicates our response was sent
    input  wire        i_valid_tx,              // from wrapper mux: TX is currently driving valid (higher priority check)

    // =========================================================================
    // Test configuration (from MBTRAIN_CONTROLLER or derived)
    // =========================================================================
    

    // =========================================================================
    // Point-test / algo done (from point-test block local to THIS die)
    // =========================================================================
    input  wire        i_pattern_detected,     // from point-test/algo: done
    input  wire [15:0] i_rx_lanes_result,   // from point-test: lane results
    input       [3:0]  i_reciever_ref_voltage, // from the point test detect let it  4'd8 for now
    // =========================================================================
    // Outputs to sideband TX (to wrapper mux -> sideband encoder/iface)
    // =========================================================================
    output reg  [3:0]  o_sideband_message,  // msg-number only
    output reg         o_valid_rx,          // asserted while sending responses

    // =========================================================================
    // Point-test enable (receiver side initiates PT in VREF-CAL conceptually) :contentReference[oaicite:9]{index=9}
    // =========================================================================
    output reg         o_pt_en,             // to point-test enable

    // =========================================================================
    // Receiver analog control word (extra VREF-CAL output) :contentReference[oaicite:10]{index=10}
    // =========================================================================
    output reg  [3:0]  o_reciever_ref_voltage, // to analog receiver vref DAC/control
    output reg         o_mainband_or_valtrain_test, // to point test detect : 0 mainband, 1 valpattern
    // =========================================================================
    // ACKs back to MBTRAIN_CONTROLLER
    // =========================================================================
    output reg         o_vref_ack,
    // =========================================================================
    // Status outputs
    // =========================================================================
    output reg         o_vref_fail,
    output reg [15:0]  o_vref_lane_mask
);

    // message numbers
    localparam [3:0] MSGNUM_START_REQ = 4'd1;
    localparam [3:0] MSGNUM_START_RSP = 4'd2;
    localparam [3:0] MSGNUM_END_REQ   = 4'd3;
    localparam [3:0] MSGNUM_END_RSP   = 4'd4;

    // RX FSM (PDF RX flow):
    // IDLE -> WAIT_START_REQ -> SEND_START_RSP -> CAL_ALGO
    //     -> WAIT_END_REQ -> SEND_END_RSP -> TEST_FINISH
    localparam [2:0]
        ST_IDLE           = 3'd0,
        ST_WAIT_START_REQ = 3'd1,
        ST_SEND_START_RSP = 3'd2,
        ST_CAL_ALGO       = 3'd3,
        ST_WAIT_END_REQ   = 3'd4,
        ST_SEND_END_RSP   = 3'd5,
        ST_TEST_FINISH    = 3'd6;

    reg [2:0] cs, ns;

    // state flops
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= ST_IDLE;
        else        cs <= ns;
    end

    // next-state logic
    always @(*) begin
        ns = cs;
        case (cs)
            ST_IDLE: begin
                if (i_en) ns = ST_WAIT_START_REQ;
            end

            ST_WAIT_START_REQ: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_START_REQ))
                    ns = ST_SEND_START_RSP;
            end

            ST_SEND_START_RSP: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_busy_negedge_detected && ~i_valid_tx)
                    ns = ST_CAL_ALGO;
            end

            ST_CAL_ALGO: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_pattern_detected)
                    ns = ST_WAIT_END_REQ;
            end

            ST_WAIT_END_REQ: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_END_REQ))
                    ns = ST_SEND_END_RSP;
            end

            ST_SEND_END_RSP: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_busy_negedge_detected && ~i_valid_tx)
                    ns = ST_TEST_FINISH;
            end

            ST_TEST_FINISH: begin
                if (!i_en) ns = ST_IDLE;
            end

            default: ns = ST_IDLE;
        endcase
    end

    // output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message     <= 4'd0;
            o_valid_rx             <= 1'b0;
            o_pt_en                <= 1'b0;
            o_reciever_ref_voltage <= 4'd8;

            o_vref_ack          <= 1'b0;

            o_vref_fail            <= 1'b0;
            o_vref_lane_mask       <= 16'h0000;
        end else begin
            // clear acks when disabled
            if (!i_en) begin
                o_vref_ack       <= 1'b0;
            end

            case (cs)
                ST_IDLE: begin
                    o_sideband_message <= 4'd0;
                    o_valid_rx         <= 1'b0;
                    o_pt_en            <= 1'b0;

                    if (ns == ST_WAIT_START_REQ) begin
                        o_vref_fail      <= 1'b0;
                        o_vref_lane_mask <= 16'h0000;
                    end

                    o_reciever_ref_voltage <= i_reciever_ref_voltage; // placeholder
                end

                ST_WAIT_START_REQ: begin
                    o_valid_rx <= 1'b0;
                    o_pt_en    <= 1'b0;
                end

                ST_SEND_START_RSP: begin
                    // send START_RSP and hold valid until "sent"
                    o_sideband_message <= MSGNUM_START_RSP;
                    o_valid_rx         <= 1'b1;

                    if (i_busy_negedge_detected && ~i_valid_tx)
                        o_valid_rx <= 1'b0;
                end

                ST_CAL_ALGO: begin
                    o_valid_rx <= 1'b0;
                    o_pt_en    <= 1'b1;
                    o_mainband_or_valtrain_test <=  i_mainband_or_valtrain_test;
                    // placeholder: later drive from sweep algo
                    o_reciever_ref_voltage <= 4'd8;

                    if (ns == ST_WAIT_END_REQ)
                        o_pt_en <= 1'b0;
                end

                ST_WAIT_END_REQ: begin
                    o_valid_rx <= 1'b0;
                    o_pt_en    <= 1'b0;
                end

                ST_SEND_END_RSP: begin
                    // latch results and respond END_RSP
                    o_vref_lane_mask <= i_rx_lanes_result;
                    o_vref_fail      <= (i_rx_lanes_result == 16'h0000);

                    o_sideband_message <= MSGNUM_END_RSP;
                    o_valid_rx         <= 1'b1;

                    if (i_busy_negedge_detected && ~i_valid_tx)
                        o_valid_rx <= 1'b0;
                end

                ST_TEST_FINISH: begin
                    o_sideband_message <= 4'd0;
                    o_valid_rx         <= 1'b0;
                    o_pt_en            <= 1'b0;

                    // assert only matching ack
                    o_vref_ack       <= 1;
                end

                default: ;
            endcase
        end
    end

endmodule
