module selfcal_rx (
    //inputs
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,


    // sideband decoded RX
    input  wire [3:0] i_decoded_sideband_message,
    input  wire       i_sideband_valid, // NEW

    // arbitration/busy + peer valid
    input  wire       i_busy_negedge_detected,
    input  wire       i_valid_tx,

    // local done from selfcal engine (same as TX uses)
    input  wire       i_selfcal_done_ack, // NEW

    //outputs
    output reg  [3:0] o_sideband_message,
    output reg        o_valid_rx,
    output reg        o_rx_self_cal_ack,
    output reg        o_test_en_rx
);

    localparam [3:0] START_REQ = 4'b0001;
    localparam [3:0] START_RSP = 4'b0010;
    localparam [3:0] END_REQ   = 4'b0011;
    localparam [3:0] END_RSP   = 4'b0100;

    localparam ST_IDLE         = 3'd0;
    localparam ST_WAIT_START   = 3'd1;
    localparam ST_RUN          = 3'd2;
    localparam ST_WAIT_END     = 3'd3;
    localparam ST_REPLY_END    = 3'd4;
    localparam ST_DONE         = 3'd5;

    reg [2:0] cs, ns;

    // valid helper (keep your style)
    

    // state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= ST_IDLE;
        else        cs <= ns;
    end

    // next state
    always @(*) begin
        ns = cs;
        case (cs)
            ST_IDLE: begin
                if (i_en) ns = ST_RUN;
            end
            ST_RUN: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_selfcal_done_ack)
                    ns = ST_WAIT_END;
            end

            ST_WAIT_END: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == END_REQ))
                    ns = ST_REPLY_END;
            end

            ST_REPLY_END: begin
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

    // output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message <= 4'b0000;
            o_rx_self_cal_ack  <= 1'b0;
            o_test_en_rx       <=1'b0 ;
        end else begin
            if (!i_en) begin
                o_rx_self_cal_ack <= 1'b0;
            end

            case (cs)
                ST_IDLE: begin
                    o_sideband_message <= 4'b0000;
                end

                ST_RUN: begin
                    o_test_en_rx <=1'b1 ;
                    // keep message stable; when done, clear it
                    if (ns == ST_WAIT_END) begin
                        o_sideband_message <= 4'b0000;
                    end
                end

                ST_WAIT_END: begin
                     o_test_en_rx <=1'b0 ;
                    if (ns == ST_REPLY_END) begin
                        o_sideband_message <= END_RSP;
                    end
                end

                ST_REPLY_END: begin
                    if (ns == ST_DONE) begin
                        o_sideband_message <= 4'b0000;
                        o_rx_self_cal_ack  <=  1'b1;
                    end
                end

                ST_DONE: begin
                    o_rx_self_cal_ack <= o_rx_self_cal_ack;
                end

                default: ;
            endcase
        end
    end

    // valid handling (same family as your other RX)
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_valid_rx <= 1'b0;
    end else begin
        // pulse/raise valid when RX issues a response
        if (   // sending START_RSP
            (cs == ST_WAIT_END   && ns == ST_REPLY_END)) begin // sending END_RSP
            o_valid_rx <= 1'b1;

        // drop valid when send completed AND TX is not owning mux
        end else if (i_busy_negedge_detected && ~i_valid_tx) begin
            o_valid_rx <= 1'b0;
        end
    end
end
endmodule