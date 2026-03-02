module tx_initiated_point_test_rx(
    input clk,
    input rst_n,
    input i_en,
    input i_mainband_or_valtrain_test,
    input i_lfsr_or_perlane,
    input [3:0] i_sideband_message,
    input i_sideband_message_valid,
    input [15:0] i_comparison_results,
    input i_valid_result,
    output reg [3:0] o_sideband_message,
    output reg [15:0] o_sideband_data,
    output reg o_msg_info,
    output reg o_valid_rx,
    output reg o_data_valid,
    output reg [1:0] o_mainband_pattern_compartor_cw,
    output reg o_comparison_valid_en,
    output reg o_test_ack_rx
);

    localparam IDLE              = 3'd0,
               WAIT_FOR_TEST_REQ = 3'd1,
               WAIT_FOR_LFSR     = 3'd2,
               CLEAR_LFSR        = 3'd3,
               WAIT_FOR_RESULT   = 3'd4,
               WAIT_FOR_END      = 3'd5,
               END_RESP          = 3'd6,
               TEST_FINISH       = 3'd7;

    reg [2:0] cs, ns;

    always @(posedge clk or negedge rst_n)
        cs <= rst_n ? ns : IDLE;

    always @(*) begin
        ns = cs;
        case(cs)
            IDLE: if(i_en) ns = WAIT_FOR_TEST_REQ;
            WAIT_FOR_TEST_REQ: if(i_sideband_message_valid && i_sideband_message==4'b0001) ns=WAIT_FOR_LFSR;
            WAIT_FOR_LFSR: if(i_sideband_message_valid && i_sideband_message==4'b0011) ns=CLEAR_LFSR;
            CLEAR_LFSR: ns = WAIT_FOR_RESULT;
            WAIT_FOR_RESULT: if(i_sideband_message_valid && i_sideband_message==4'b0101) ns=WAIT_FOR_END;
            WAIT_FOR_END: if(i_sideband_message_valid && i_sideband_message==4'b0111) ns=END_RESP;
            END_RESP: ns = TEST_FINISH;
            TEST_FINISH: if(!i_en) ns=IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            o_sideband_message <= 4'b0000;
            o_sideband_data <= 16'b0;
            o_msg_info <= 0;
            o_valid_rx <= 0;
            o_data_valid <= 0;
            o_mainband_pattern_compartor_cw <= 2'b00;
            o_comparison_valid_en <= 0;
            o_test_ack_rx <= 0;
        end else begin
            o_valid_rx <= 0;
            o_data_valid <= 0;
            o_comparison_valid_en <= 0;
         

            case(cs)
                WAIT_FOR_TEST_REQ: if(ns==WAIT_FOR_LFSR) begin o_sideband_message<=4'b0010; o_valid_rx<=1; end
                WAIT_FOR_LFSR: if(ns==CLEAR_LFSR) begin o_sideband_message<=4'b0100; o_valid_rx<=1; end
                CLEAR_LFSR: if(ns==WAIT_FOR_RESULT) begin
                    case({i_mainband_or_valtrain_test,i_lfsr_or_perlane})
                        2'b00: o_mainband_pattern_compartor_cw<=2'b10;
                        2'b01: o_mainband_pattern_compartor_cw<=2'b11;
                        default: o_comparison_valid_en<=1;
                    endcase
                end
                WAIT_FOR_RESULT: if(ns==WAIT_FOR_END) begin
                    o_sideband_message<=4'b0110; o_valid_rx<=1;
                    o_msg_info<=i_valid_result; o_sideband_data<=i_comparison_results;
                end
                WAIT_FOR_END: if(ns==END_RESP) begin o_sideband_message<=4'b1000; o_valid_rx<=1; end
                END_RESP: if(ns==TEST_FINISH) o_test_ack_rx<=1;
            endcase
        end
    end
    // ------------------------------------------
// Latch TEST ACK (RX)
// ------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        o_test_ack_rx <= 1'b0;

    else if (!i_en)
        o_test_ack_rx <= 1'b0;     // clear when disabled

    else if (cs == TEST_FINISH)
        o_test_ack_rx <= 1'b1;     // latch high
end
endmodule