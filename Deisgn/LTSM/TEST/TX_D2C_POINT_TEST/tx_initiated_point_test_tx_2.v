module tx_initiated_point_test_tx(
    input        clk,
    input        rst_n,
    input        i_en,
    input        i_mainband_or_valtrain_test,
    input        i_lfsr_or_perlane,
    input        i_pattern_finished,
    input [3:0]  i_sideband_message,
    input        i_sideband_message_valid,
    output reg [3:0]  o_sideband_message,
    output reg        o_valid_tx,
    output     [15:0] o_sideband_data,
    output reg        o_data_valid,
    output reg        o_val_pattern_en,
    output reg [1:0]  o_mainband_pattern_generator_cw,
    output reg        o_test_ack_tx
);

    // FSM states
    localparam IDLE          = 3'd0,
               START_REQ     = 3'd1,
               LFSR_CLEAR_REQ= 3'd2,
               SEND_PATTERN  = 3'd3,
               RESULT_REQ    = 3'd4,
               END_REQ       = 3'd5,
               TEST_FINISHED = 3'd6;

    reg [2:0] cs, ns;

    // Sideband data (pattern info)
    reg sb_data_pattern, sb_burst_count, sb_comparison_mode;
    assign o_sideband_data = {11'h000, sb_comparison_mode, sb_burst_count, 3'b000, sb_data_pattern};

    // Sequential
    always @(posedge clk or negedge rst_n)
        cs <= rst_n ? ns : IDLE;

    // Next-state logic
    always @(*) begin
        ns = cs;
        case(cs)
            IDLE:          if(i_en) ns = START_REQ;
            START_REQ:     if(i_sideband_message_valid && i_sideband_message==4'b0010) ns = LFSR_CLEAR_REQ;
            LFSR_CLEAR_REQ:if(i_sideband_message_valid && i_sideband_message==4'b0100) ns = SEND_PATTERN;
            SEND_PATTERN:  if(i_pattern_finished) ns = RESULT_REQ;
            RESULT_REQ:    if(i_sideband_message_valid && i_sideband_message==4'b0110) ns = END_REQ;
            END_REQ:       if(i_sideband_message_valid && i_sideband_message==4'b1000) ns = TEST_FINISHED;
            TEST_FINISHED: if(!i_en) ns = IDLE;
        endcase
    end

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            o_sideband_message <= 4'b0000;
            o_valid_tx <= 0;
            o_data_valid <= 0;
            o_test_ack_tx <= 0;
            o_val_pattern_en <= 0;
            sb_data_pattern <= 0;
            sb_burst_count <= 0;
            sb_comparison_mode <= 0;
            o_mainband_pattern_generator_cw <= 2'b00;
        end else begin
            o_valid_tx <= 0;
            o_data_valid <= 0;
            
            

            case(cs)
                IDLE: begin
                    if(ns==START_REQ) begin
                        o_sideband_message <= 4'b0001;
                        o_valid_tx <= 1;
                    end
                end
                START_REQ: if(ns==LFSR_CLEAR_REQ) begin
                    o_sideband_message <= 4'b0011;
                    o_valid_tx <= 1;
                end
                LFSR_CLEAR_REQ: if(ns==SEND_PATTERN) begin
                    case({i_mainband_or_valtrain_test,i_lfsr_or_perlane})
                        2'b00: o_mainband_pattern_generator_cw <= 2'b10;
                        2'b01: o_mainband_pattern_generator_cw <= 2'b11;
                        default: o_val_pattern_en <= 1;
                    endcase
                end
                SEND_PATTERN: if(ns==RESULT_REQ) begin
                    o_sideband_message <= 4'b0101;
                    o_valid_tx <= 1;
                    o_data_valid <= 1;
                    o_val_pattern_en <= 0;
                    o_mainband_pattern_generator_cw <= 2'b00;
                end
                RESULT_REQ: if(ns==END_REQ) begin
                    o_sideband_message <= 4'b0111;
                    o_valid_tx <= 1;
                end
                END_REQ: if(ns==TEST_FINISHED) begin
                    o_sideband_message <= 4'b0000;
                    o_test_ack_tx <= 1;
                end
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        o_test_ack_tx <= 0;
    else if(cs == TEST_FINISHED)
        o_test_ack_tx <= 1;   // latch high
    else if(!i_en)
        o_test_ack_tx <= 0;   // clear when disabled
end

endmodule