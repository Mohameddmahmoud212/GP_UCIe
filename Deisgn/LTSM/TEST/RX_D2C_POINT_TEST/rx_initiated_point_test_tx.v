module rx_initiated_point_test_tx #(
    parameter SB_MSG_WIDTH = 4
)(
    input                           i_clk,
    input                           i_rst_n,

    input                           i_rx_d2c_pt_en,
    input                           i_datavref_or_valvref,
    input                           i_pattern_finished,

    input                           i_rx_msg_valid,
    input       [SB_MSG_WIDTH-1:0]    i_decoded_SB_msg,

    output  reg [SB_MSG_WIDTH-1:0]    o_encoded_SB_msg_tx,
    output  reg                      o_sb_data_pattern,
    output  reg                      o_sb_burst_count,
    output  reg                      o_sb_comparison_mode,
    output  reg [1:0]                 o_clock_phase,
    output  reg                      o_valid_tx,

    output  reg                      o_val_pattern_en,
    output  reg [1:0]                 o_mainband_pattern_generator_cw,

    output  reg                      o_rx_d2c_pt_done_tx
);

localparam [3:0]
    IDLE                = 0,
    SEND_START_RESP     = 1,
    SEND_LFSR_CLR_REQ     = 2,
    WAIT_LFSR_CLR_RESP    = 3,
    SEND_PATTERN          = 4,
    SEND_COUNT_DONE_REQ    = 5,
    WAIT_COUNT_DONE_RESP   = 6,
    WAIT_END_REQ           = 7,
    SEND_END_RESP           = 8,
    TEST_DONE              = 9;

reg [3:0] CS, NS;

// state register
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end

// next state logic
always @(*) begin
    NS = CS;
    case (CS)
        IDLE:
            if (i_rx_d2c_pt_en && i_rx_msg_valid && i_decoded_SB_msg == 1)
                NS = SEND_START_RESP;

        SEND_START_RESP:
            NS = SEND_LFSR_CLR_REQ;

        SEND_LFSR_CLR_REQ:
            NS = WAIT_LFSR_CLR_RESP;

        WAIT_LFSR_CLR_RESP:
            if (i_rx_msg_valid && i_decoded_SB_msg == 4)
                NS = SEND_PATTERN;

        SEND_PATTERN:
            if (i_pattern_finished)
                NS = SEND_COUNT_DONE_REQ;

        SEND_COUNT_DONE_REQ:
            NS = WAIT_COUNT_DONE_RESP;

        WAIT_COUNT_DONE_RESP:
            if (i_rx_msg_valid && i_decoded_SB_msg == 6)
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
        o_valid_tx                      <= 0;
        o_encoded_SB_msg_tx              <= 0;
        o_sb_data_pattern                <= 0;
        o_sb_burst_count                  <= 0;
        o_sb_comparison_mode              <= 0;
        o_clock_phase                     <= 0;
        o_val_pattern_en                  <= 0;
        o_mainband_pattern_generator_cw   <= 0;
        o_rx_d2c_pt_done_tx                <= 0;
    end else begin
        o_valid_tx <= 0;
        o_val_pattern_en <= 0;
        o_mainband_pattern_generator_cw <= 2'b00;

        case (CS)
            SEND_START_RESP: begin
                o_valid_tx <= 1;
                o_encoded_SB_msg_tx <= 2;
                o_sb_data_pattern <= 0;
                o_sb_comparison_mode <= 0;
                o_clock_phase <= 0;
                o_sb_burst_count <= (i_datavref_or_valvref == 0);
            end

            SEND_LFSR_CLR_REQ: begin
                o_valid_tx <= 1;
                o_encoded_SB_msg_tx <= 3;
                o_mainband_pattern_generator_cw <= 2'b01;
            end

            SEND_PATTERN: begin
                if (i_datavref_or_valvref == 0)
                    o_mainband_pattern_generator_cw <= 2'b10;
                else
                    o_val_pattern_en <= 1;
            end

            SEND_COUNT_DONE_REQ: begin
                o_valid_tx <= 1;
                o_encoded_SB_msg_tx <= 5;
            end

            SEND_END_RESP: begin
                o_valid_tx <= 1;
                o_encoded_SB_msg_tx <= 8;
            end

            TEST_DONE: begin
                o_rx_d2c_pt_done_tx <= 1;
            end
        endcase

        if (!i_rx_d2c_pt_en)
            o_rx_d2c_pt_done_tx <= 0;
    end
end

endmodule