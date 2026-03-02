module tx_initiated_point_test_wrapper(
    input        clk,
    input        rst_n,
    input        i_en,
    input        i_mainband_or_valtrain_test,
    input        i_lfsr_or_perlane,
    input        i_pattern_finished,
    input [15:0] i_comparison_results,
    input        i_valid_result,

    output [3:0]  o_sideband_message,
    output        o_valid,
    output        o_data_valid,
    output        o_msg_info,
    output [15:0] o_sideband_data,
    output        o_val_pattern_en,
    output [1:0]  o_mainband_pattern_generator_cw,
    output [1:0]  o_mainband_pattern_compartor_cw,
    output        o_comparison_valid_en,
    output        o_test_ack,
    output        o_valid_result,
    output [15:0] o_mainband_lanes_result
);

    // TX → RX internal wires
    wire [3:0] tx_msg;
    wire tx_valid;
    wire tx_data_valid;
    wire tx_ack;

    wire [3:0] rx_msg;
    wire rx_valid;
    wire rx_ack;

    // ✅ MUST BE WIRES (not reg)
    wire [3:0] sideband_msg;
    wire sideband_valid;

    // ---------------------------------
    // TX
    // ---------------------------------
    tx_initiated_point_test_tx tx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_lfsr_or_perlane(i_lfsr_or_perlane),
        .i_pattern_finished(i_pattern_finished),
        .i_sideband_message(sideband_msg),
        .i_sideband_message_valid(sideband_valid),
        .o_sideband_message(tx_msg),
        .o_valid_tx(tx_valid),
        .o_sideband_data(o_sideband_data),
        .o_data_valid(tx_data_valid),
        .o_val_pattern_en(o_val_pattern_en),
        .o_mainband_pattern_generator_cw(o_mainband_pattern_generator_cw),
        .o_test_ack_tx(tx_ack)
    );

    // ---------------------------------
    // RX
    // ---------------------------------
    tx_initiated_point_test_rx rx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_lfsr_or_perlane(i_lfsr_or_perlane),
        .i_sideband_message(tx_msg),
        .i_sideband_message_valid(tx_valid),
        .i_comparison_results(i_comparison_results),
        .i_valid_result(i_valid_result),
        .o_sideband_message(rx_msg),
        .o_sideband_data(),
        .o_msg_info(o_msg_info),
        .o_valid_rx(rx_valid),
        .o_data_valid(),
        .o_mainband_pattern_compartor_cw(o_mainband_pattern_compartor_cw),
        .o_comparison_valid_en(o_comparison_valid_en),
        .o_test_ack_rx(rx_ack)
    );

    // ---------------------------------
    // Feedback RX → TX
    // ---------------------------------
    assign sideband_msg   = rx_msg;
    assign sideband_valid = rx_valid;

    // ---------------------------------
    // Wrapper Outputs
    // ---------------------------------
    assign o_sideband_message       = tx_msg;
    assign o_valid                  = tx_valid | rx_valid;
    assign o_data_valid             = tx_data_valid;
    assign o_test_ack               = tx_ack & rx_ack;
    assign o_valid_result           = i_valid_result;
    assign o_mainband_lanes_result  = i_comparison_results;

endmodule