module rx_cal_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,


    // from sideband decoder (RX)
    input  wire [3:0] i_decoded_sideband_message,
    input  wire       i_sideband_valid,

    // from sideband interface / wrapper
    input  wire       i_busy_negedge_detected, // "packet sent done" pulse
    input  wire       i_valid_tx,              // TX owns mux / active now

    // from RX calibration engine (point-test / algo)
    input  wire       i_rx_cal_done_ack,       // goes high when calibration finishes

    // to sideband encoder (TX direction of RX block)
    output reg  [3:0] o_sideband_message,
    output reg        o_valid_rx,

    // NEW: enable to start the actual test/calibration engine
    output reg        o_rx_cal_en,      // asserted during ST_RUN

    // acks back to mbtrain_controller
    output reg        o_rx_cal_ack
);

    // ------------------------------------------------------------
    // Sideband message numbers (shared convention)
    // ------------------------------------------------------------
    localparam [3:0] START_REQ = 4'd1;
    localparam [3:0] START_RSP = 4'd2;
    localparam [3:0] END_REQ   = 4'd3;
    localparam [3:0] END_RSP   = 4'd4;

    // ------------------------------------------------------------
    // FSM
    // IDLE -> WAIT_START_REQ -> RUN (send START_RSP + run test)
    //     -> WAIT_END_REQ -> REPLY_END (send END_RSP) -> DONE
    // ------------------------------------------------------------
    localparam [2:0]
        ST_IDLE       = 3'd0,
        ST_WAIT_START = 3'd1,
        ST_RUN        = 3'd2,
        ST_WAIT_END   = 3'd3,
        ST_REPLY_END  = 3'd4,
        ST_DONE       = 3'd5;

    reg [2:0] cs, ns;

    // ------------------------------------------------------------
    // state update
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= ST_IDLE;
        else        cs <= ns;
    end

    // ------------------------------------------------------------
    // next state logic (always gate decoded message with valid)
    // ------------------------------------------------------------
    always @(*) begin
        ns = cs;
        case (cs)
            ST_IDLE: begin
                if (i_en) ns = ST_WAIT_START;
            end

            ST_WAIT_START: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == START_REQ))
                    ns = ST_RUN;
            end

            ST_RUN: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_rx_cal_done_ack)
                    ns = ST_WAIT_END;
            end

            ST_WAIT_END: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == END_REQ))
                    ns = ST_REPLY_END;
            end

            ST_REPLY_END: begin
                // BEST PRACTICE: enter DONE when END_RSP transmission actually finished
                if (!i_en) ns = ST_IDLE;
                else if (i_busy_negedge_detected && ~i_valid_tx)
                    ns = ST_DONE;
            end

            ST_DONE: begin
                if (!i_en) ns = ST_IDLE;
            end

            default: ns = ST_IDLE;
        endcase
    end

    // ------------------------------------------------------------
    // output logic: sideband message + test enable + controller acks
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message <= 4'd0;

            o_rx_cal_en        <= 1'b0;

            o_rx_cal_ack   <= 1'b0;
        end else begin

            // clear acks when disabled
            if (!i_en) begin
                o_rx_cal_ack <= 1'b0;
            end
            o_rx_cal_en <= 1'b0;

            case (cs)
                ST_IDLE: begin
                    o_sideband_message <= 4'd0;
                end

                ST_WAIT_START: begin
                    o_sideband_message <= 4'd0;
                end

                ST_RUN: begin
                    o_rx_cal_en <= 1'b1;
                    if (cs == ST_WAIT_START && ns == ST_RUN) begin
                        o_sideband_message <= START_RSP;
                    end else begin
                        if (i_busy_negedge_detected && ~i_valid_tx)
                            o_sideband_message <= 4'd0;
                    end
                end

                ST_WAIT_END: begin
                    o_sideband_message <= 4'd0;
                end

                ST_REPLY_END: begin
                    o_sideband_message <= END_RSP;
                end

                ST_DONE: begin
                    o_sideband_message <= 4'd0;
                    o_rx_cal_ack <= 1'b1;
                end

                default: ;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_rx <= 1'b0;
        end else begin
            if ((cs == ST_WAIT_START && ns == ST_RUN) ||
                (cs == ST_WAIT_END   && ns == ST_REPLY_END)) begin
                o_valid_rx <= 1'b1;

            // drop when interface says send is done AND TX not driving
            end else if (i_busy_negedge_detected && ~i_valid_tx) begin
                o_valid_rx <= 1'b0;
            end
        end
    end

endmodule
