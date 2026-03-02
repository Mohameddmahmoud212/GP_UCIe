module rx_initiated_point_test_rx #(
    parameter SB_MSG_WIDTH = 4
)(
    input                           i_clk,
    input                           i_rst_n,
    input                           i_rx_d2c_pt_en,
    input                           i_rx_msg_valid,
    input       [SB_MSG_WIDTH-1:0]    i_decoded_SB_msg,
    input                           i_datavref_or_valvref,

    output  reg [SB_MSG_WIDTH-1:0]     o_encoded_SB_msg_rx,
    output  reg                       o_valid_rx,
    output  reg                       o_comparison_valid_en,
    output  reg [1:0]                  o_mainband_pattern_comparator_cw,
    output  reg                       o_rx_d2c_pt_done_rx
);

localparam [3:0]
    IDLE                 = 0,
    SEND_START_REQ        = 1,
    WAIT_START_RESP        = 2,
    WAIT_LFSR_CLR_REQ       = 3,
    SEND_LFSR_CLR_RESP       = 4,
    WAIT_COUNT_DONE_REQ      = 5,
    SEND_COUNT_DONE_RESP      = 6,
    WAIT_END_REQ             = 7,
    SEND_END_RESP             = 8,
    TEST_DONE                = 9;

reg [3:0] CS, NS;

// state register
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end

// next state
always @(*) begin
    NS = CS;
    case (CS)
        IDLE:
            if (i_rx_d2c_pt_en)
                NS = SEND_START_REQ;

        SEND_START_REQ:
            NS = WAIT_START_RESP;

        WAIT_START_RESP:
            if (i_rx_msg_valid && i_decoded_SB_msg == 2)
                NS = WAIT_LFSR_CLR_REQ;

        WAIT_LFSR_CLR_REQ:
            if (i_rx_msg_valid && i_decoded_SB_msg == 3)
                NS = SEND_LFSR_CLR_RESP;

        SEND_LFSR_CLR_RESP:
            NS = WAIT_COUNT_DONE_REQ;

        WAIT_COUNT_DONE_REQ:
            if (i_rx_msg_valid && i_decoded_SB_msg == 5)
                NS = SEND_COUNT_DONE_RESP;

        SEND_COUNT_DONE_RESP:
            NS = WAIT_END_REQ;

        WAIT_END_REQ:
            if (i_rx_msg_valid && i_decoded_SB_msg == 7)
                NS = SEND_END_RESP;

        SEND_END_RESP:
            NS = TEST_DONE;

        TEST_DONE:
            if (!i_rx_d2c_pt_en)
                NS = IDLE;

        default:
            NS = IDLE;
    endcase
end

// output logic (single driver for done)
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_valid_rx <= 0;
        o_encoded_SB_msg_rx <= 0;
        o_comparison_valid_en <= 0;
        o_mainband_pattern_comparator_cw <= 0;
        o_rx_d2c_pt_done_rx <= 0;
    end else begin
        o_valid_rx <= 0;

        case (CS)
            SEND_START_REQ: begin
                o_valid_rx <= 1;
                o_encoded_SB_msg_rx <= 1;
                o_comparison_valid_en <= 1;
            end

            SEND_LFSR_CLR_RESP: begin
                o_valid_rx <= 1;
                o_encoded_SB_msg_rx <= 4;
                o_mainband_pattern_comparator_cw <= 2'b01;
            end

            SEND_COUNT_DONE_RESP: begin
                o_valid_rx <= 1;
                o_encoded_SB_msg_rx <= 6;
                o_comparison_valid_en <= 0;
                o_mainband_pattern_comparator_cw <= 2'b00;
            end

            SEND_END_RESP: begin
                o_valid_rx <= 1;
                o_encoded_SB_msg_rx <= 8;
            end

            TEST_DONE: begin
                o_rx_d2c_pt_done_rx <= 1;
            end
        endcase

        if (!i_rx_d2c_pt_en)
            o_rx_d2c_pt_done_rx <= 0;
    end
end

endmodule