/*==============================================================================
-- SELFCAL TX (UPDATED: mode + split ACKs + sideband_valid gating + !i_en escape)
-- i_mode: this state does not need start handshake it go to the run state after enable 
--   0: SPEED_IDLE
--   1: TXSELFCAL
-- Sideband codes (fixed like the rest of your design):
--   START_REQ = 0001
--   START_RSP = 0010
--   END_REQ   = 0011
--   END_RSP   = 0100
==============================================================================*/
module selfcal_tx (
    //inputs
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,

    // sideband decoded RX
    input  wire [3:0] i_decoded_sideband_message,
    input  wire       i_sideband_valid, // NEW (non-optional)

    // valid/busy arbitration
    input  wire       i_busy_negedge_detected,
    input  wire       i_valid_rx,

    // "done" from local selfcal engine (you can tie it to a timer or analog done)
    input  wire       i_selfcal_done_ack, // NEW

    //outputs
    output reg  [3:0] o_sideband_message,
    output reg        o_valid_tx,
    output reg        o_test_en ,
    // split ACKs back to controller (same naming as mbtrain_controller expects)
    output reg        o_tx_self_cal_ack
);

    localparam [3:0] START_REQ = 4'b0001;
    localparam [3:0] START_RSP = 4'b0010;
    localparam [3:0] END_REQ   = 4'b0011;
    localparam [3:0] END_RSP   = 4'b0100;

    localparam IDLE         = 3'd0;
    localparam START_REQ_ST = 3'd1;
    localparam RUN_ST       = 3'd2;
    localparam END_REQ_ST   = 3'd3;
    localparam DONE_ST      = 3'd4;

    reg [2:0] cs, ns;

    // state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= IDLE;
        else        cs <= ns;
    end

    // next state
    always @(*) begin
        ns = cs;
        case (cs)
            IDLE: begin
                if (i_en) ns = RUN_ST;
            end


            RUN_ST: begin
                if (!i_en) ns = IDLE;
                else if (i_selfcal_done_ack)
                    ns = END_REQ_ST;
            end

            END_REQ_ST: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == END_RSP))
                    ns = DONE_ST;
            end

            DONE_ST: begin
                if (!i_en) ns = IDLE;
            end

            default: ns = IDLE;
        endcase
    end

    // outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message <= 4'b0000;
            o_tx_self_cal_ack   <= 1'b0;
            o_test_en          <= 1'b0;
        end else begin
            // clear acks when disabled
            if (!i_en) begin
                o_tx_self_cal_ack  <= 1'b0;
            end

            case (cs)
                IDLE: begin
                    o_sideband_message <= 4'b0000;
                end

                RUN_ST: begin
                    o_test_en          <= 1'b1;
                    if (ns == END_REQ_ST) begin
                        o_sideband_message <= END_REQ;
                    end
                end

                END_REQ_ST: begin
                     o_test_en          <= 1'b0;    
                    if (ns == DONE_ST) begin
                        o_sideband_message <= 4'b0000;

                        // assert ONLY one ack based on mode; held high in DONE_ST
                        
                        o_tx_self_cal_ack <= 1'b1;
                    end
                end

                DONE_ST: begin
                    // hold ack high until i_en drops
                    o_tx_self_cal_ack <= o_tx_self_cal_ack;
                end

                default: ;
            endcase
        end
    end

    // valid handling: pulse when sending START_REQ or END_REQ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_tx <= 1'b0;
        end else if ((cs == IDLE && ns == START_REQ_ST) || (cs == RUN_ST && ns == END_REQ_ST)) begin
            o_valid_tx <= 1'b1;
        end else if (i_busy_negedge_detected && ~i_valid_rx) begin
            o_valid_tx <= 1'b0;
        end
    end

endmodule