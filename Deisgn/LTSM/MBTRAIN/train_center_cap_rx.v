module train_center_cal_rx  (
    //inputs 
        input  wire       clk,
        input  wire       rst_n,
        input  wire       i_en,

        // NEW: 0 VALTRAINCENTER, 1 DATATRAINCENTER1, 2 DATATRAINCENTER2

        // communicating with sideband 
        input  wire [3:0] i_decoded_sideband_message,
        input  wire       i_sideband_valid,              // NEW (non-optional)

        // handling_mux_priorities 
        input  wire       i_busy_negedge_detected,
        input  wire       i_valid_tx,

        // test configurations (kept, can be unused)
        input  wire       i_mainband_or_valtrain_test,
        input  wire       i_lfsr_or_perlane,

        // DONE from algo / point-test (same meaning as your i_test_ack)
        input  wire       i_algo_done_ack,

        // (optional) results bus (kept)
        input  wire [15:0] i_tx_lanes_result,

    //output 
        // communicating with sideband
        output reg  [3:0] o_sideband_message,
        output reg        o_valid_rx,

        // enabling point test block (RX responder عادةً مش بيملك PT، بس هنسيبها زي ما هي عندك)
        output reg        o_pt_en,
        output reg        o_eye_width_sweep_en,

        // NEW: split ACKs back to controller
        output reg        o_traincenter_ack
);
    
    localparam [3:0] MSGNUM_START_REQ = 4'd1;
    localparam [3:0] MSGNUM_START_RSP = 4'd2;
    localparam [3:0] MSGNUM_END_REQ   = 4'd3;
    localparam [3:0] MSGNUM_END_RSP   = 4'd4;
    /*------------------------------------------------------------------------------
    -- fsm states   
    ------------------------------------------------------------------------------*/
    localparam IDLE               = 3'd0;
    localparam WAIT_FOR_START_REQ = 3'd1;
    localparam CAL_ALGO           = 3'd2;
    localparam WAIT_FOR_END_REQ   = 3'd3;
    localparam SEND_END_RESPONSE  = 3'd4;
    localparam TEST_FINISHED      = 3'd5;

    reg [2:0] cs, ns;


    /*------------------------------------------------------------------------------
    -- current state update   
    ------------------------------------------------------------------------------*/
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) cs <= IDLE;
        else        cs <= ns;
    end

    /*------------------------------------------------------------------------------
    -- next state logic  
    ------------------------------------------------------------------------------*/
    always @(*) begin
        ns = cs;
        case (cs)
            IDLE: begin
                if (i_en) ns = WAIT_FOR_START_REQ;
            end

            WAIT_FOR_START_REQ: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_START_REQ)) // START_REQ
                    ns = CAL_ALGO;
            end

            CAL_ALGO: begin
                if (!i_en) ns = IDLE;
                else if (i_algo_done_ack)
                    ns = WAIT_FOR_END_REQ;
            end

            WAIT_FOR_END_REQ: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_END_REQ)) // END_REQ
                    ns = SEND_END_RESPONSE;
            end

            SEND_END_RESPONSE: begin
                if (!i_en) ns = IDLE;
                else if (i_busy_negedge_detected && ~i_valid_tx)
                    ns = TEST_FINISHED;
            end

            TEST_FINISHED: begin
                if (!i_en) ns = IDLE;
            end

            default: ns = IDLE;
        endcase
    end

    /*------------------------------------------------------------------------------
    -- output logic  
    ------------------------------------------------------------------------------*/
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            o_sideband_message     <= 4'b0000;
            o_pt_en                <= 1'b0;
            o_eye_width_sweep_en   <= 1'b0;

            o_traincenter_ack   <= 1'b0;
           
        end else begin
            // clear ACKs when disabled
            if (!i_en) begin
                o_traincenter_ack   <= 1'b0;
               
            end

            case (cs)
                IDLE: begin
                    o_sideband_message   <= 4'b0000;
                    o_pt_en              <= 1'b0;
                    o_eye_width_sweep_en <= 1'b0;

                    // acks cleared above when !i_en
                end

                WAIT_FOR_START_REQ: begin
                    // when we see START_REQ -> enter CAL_ALGO and respond START_RSP
                    if (cs == WAIT_FOR_START_REQ && ns == CAL_ALGO) begin
                        o_sideband_message <= MSGNUM_START_RSP; // START_RSP
                        o_pt_en            <= 1'b1;    // keep your behavior
                    end
                end

                CAL_ALGO: begin
                    // when done -> stop PT
                    if (cs == CAL_ALGO && ns == WAIT_FOR_END_REQ) begin
                        o_pt_en <= 1'b0;
                    end
                end

                WAIT_FOR_END_REQ: begin
                    // respond END_RSP when we see END_REQ
                    if (cs == WAIT_FOR_END_REQ && ns == SEND_END_RESPONSE) begin
                        o_sideband_message <= MSGNUM_END_RSP; // END_RSP
                    end
                end

                SEND_END_RESPONSE: begin
                    // once our valid drops (handshake complete) -> finish
                    if (ns == TEST_FINISHED) begin
                        o_sideband_message <= 4'b0000;
                        o_traincenter_ack   <= 1'b1 ;
                    end
                end

                TEST_FINISHED: begin
                    // hold ack high while enabled
                    o_traincenter_ack   <= o_traincenter_ack;
                   
                end

                default: ;
            endcase
        end
    end

    /*------------------------------------------------------------------------------
    -- handling valid signal (aligned with TX style)
    ------------------------------------------------------------------------------*/
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_valid_rx <= 1'b0;
    end else begin
        // pulse/raise valid when RX issues a response
        if ((cs == WAIT_FOR_START_REQ && ns == CAL_ALGO) ||   // sending START_RSP
            (cs == WAIT_FOR_END_REQ   && ns == SEND_END_RESPONSE)) begin // sending END_RSP
            o_valid_rx <= 1'b1;

        // drop valid when send completed AND TX is not owning mux
        end else if (i_busy_negedge_detected && ~i_valid_tx) begin
            o_valid_rx <= 1'b0;
        end
    end
end

endmodule
