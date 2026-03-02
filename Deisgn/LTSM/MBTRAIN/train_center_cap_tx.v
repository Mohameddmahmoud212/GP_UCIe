module train_center_cal_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,

    // NEW: 0 VALTRAINCENTER, 1 DATATRAINCENTER1, 2 DATATRAINCENTER1

    // sideband RX decoded
    input  wire [3:0]  i_decoded_sideband_message,
    input  wire        i_sideband_valid,

    // mux/busy
    input  wire        i_busy_negedge_detected,
    input  wire        i_valid_rx,

    // config
    input  wire        i_mainband_or_valtrain_test, // use it bec. VALTRAINCENTER use valid pattern  1
                                                    // DATATRAINCENTER1 , DATATRAINCENTER1 use data pattern 0
    input  wire        i_lfsr_or_perlane,            // same 

    // algo done from point-test
    input  wire        i_algo_done_ack, // come from pattern generator when finish sending the pattern 

    // results
    input  wire [15:0] i_tx_lanes_result, // come from point test with the final result 

    // sideband TX
    output reg  [3:0]  o_sideband_message,
    output reg         o_valid_tx,

    // enables
    output reg         o_pt_en,
    output reg         o_eye_width_sweep_en, // using to make the sweep test not using for now 

    output reg         o_mainband_or_valtrain_test,
    output reg  [15:0] o_vref_lane_mask ,
    output reg         o_vref_fail      ,
    // PI word
    output reg  [3:0]  o_pi_step,

    // NEW: split final acks
    output reg         o_traincenter_ack
);

    localparam [3:0] MSGNUM_START_REQ = 4'd1;
    localparam [3:0] MSGNUM_START_RSP = 4'd2;
    localparam [3:0] MSGNUM_END_REQ   = 4'd3;
    localparam [3:0] MSGNUM_END_RSP   = 4'd4;

    localparam IDLE         = 3'd0;
    localparam START_REQ_ST = 3'd1;
    localparam CAL_ALGO     = 3'd2;
    localparam END_REQ_ST   = 3'd3;
    localparam DONE         = 3'd4;

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
                if (i_en) ns = START_REQ_ST;
            end

            START_REQ_ST: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_START_RSP))
                    ns = CAL_ALGO;
            end

            CAL_ALGO: begin
                if (!i_en) ns = IDLE;
                else if (i_algo_done_ack)
                    ns = END_REQ_ST;
            end

            END_REQ_ST: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_decoded_sideband_message == MSGNUM_END_RSP))
                    ns = DONE;
            end

            DONE: begin
                if (!i_en) ns = IDLE;
            end

            default: ns = IDLE;
        endcase
    end

    // outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message <= 4'b0000;
            o_pt_en            <= 1'b0;
            o_eye_width_sweep_en <= 1'b0;
            o_mainband_or_valtrain_test <= 1'b0;
            o_pi_step          <= 4'd0;
            o_vref_lane_mask   <=16'd0;
            o_vref_fail        <=1'b0 ;
            o_traincenter_ack   <= 1'b0;
        end else begin
            // clear acks when disabled
            if (!i_en) begin
                o_traincenter_ack   <= 1'b0;
            end

            case (cs)
                IDLE: begin
                    o_sideband_message <= 4'b0000;
                    o_pt_en            <= 1'b0;
                    o_eye_width_sweep_en <= 1'b0;
                    o_mainband_or_valtrain_test <= 1'b0;

                    if (ns == START_REQ_ST) begin
                        o_sideband_message <= 4'b0001; // START_REQ
                        o_pi_step <= 4'd0;
                        o_vref_lane_mask   <=16'd0;
                        o_vref_fail        <=1'b0 ;
                    end
                end

                START_REQ_ST: begin
                    if (cs == START_REQ_ST && ns == CAL_ALGO) begin
                        o_pt_en <= 1'b1;
                        o_mainband_or_valtrain_test <= i_mainband_or_valtrain_test;
                    end
                end

                CAL_ALGO: begin
                    o_pi_step <= o_pi_step + 1'b1;

                    if (cs == CAL_ALGO && ns == END_REQ_ST) begin
                        o_pt_en <= 1'b0;
                        o_sideband_message <= 4'b0011; // END_REQ
                        o_vref_lane_mask <= i_tx_lanes_result;
                        o_vref_fail      <= (i_tx_lanes_result == 16'h0000);
                    end
                end

                END_REQ_ST: begin
                    if (cs == END_REQ_ST && ns == DONE) begin
                        o_sideband_message <= 4'b0000;

                        o_traincenter_ack   <= 1'b1;
                    end
                end

                DONE: begin
                    // hold ACKs until i_en drops
                    o_traincenter_ack   <= o_traincenter_ack;
                end
            endcase
        end
    end

    // valid pulse handling 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_tx <= 1'b0;
        end else begin
            if ((cs == IDLE && ns == START_REQ_ST) || (cs == CAL_ALGO && ns == END_REQ_ST)) begin
                o_valid_tx <= 1'b1;
            end else if (i_busy_negedge_detected && ~i_valid_rx) begin
                o_valid_tx <= 1'b0;
            end
        end
    end

endmodule
