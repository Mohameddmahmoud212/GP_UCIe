module rx_initiated_point_test_wrapper (
    input                       i_clk,
    input                       i_rst_n,

    input                       i_rx_d2c_pt_en,
    input                       i_datavref_or_valvref,
    input                       i_pattern_finished,
    input       [15:0]           i_comparison_results,

 
    input                       i_rx_msg_valid,
    input       [3:0]            i_decoded_SB_msg,

    output  reg [3:0]            o_encoded_SB_msg,
    output      [15:0]           o_tx_data_bus,
    output                      o_tx_msg_valid,
    output                      o_tx_data_valid,

    output                      o_rx_d2c_pt_done,
    output      [15:0]           o_comparison_result,

    output                      o_val_pattern_en,
    output      [1:0]            o_mainband_pattern_generator_cw,
    output                      o_comparison_valid_en,
    output      [1:0]            o_mainband_pattern_comparator_cw
);

    localparam SB_MSG_WIDTH = 4;

    // internal sideband
    wire wp_tx_valid, wp_rx_valid;
    wire [SB_MSG_WIDTH-1:0] wp_tx_encoded_SB_msg, wp_rx_encoded_SB_msg;
    wire wp_rx_d2c_pt_done_tx, wp_rx_d2c_pt_done_rx;

    wire sb_data_pattern;
    wire sb_burst_count;
    wire sb_comparison_mode;
    wire [1:0] sb_clock_phase;

    // data bus packing
    assign o_tx_data_bus = {
        11'b0,
        sb_comparison_mode,
        sb_burst_count,
        sb_clock_phase,
        sb_data_pattern
    };

    assign o_rx_d2c_pt_done  = wp_rx_d2c_pt_done_tx & wp_rx_d2c_pt_done_rx;
    assign o_comparison_result = i_comparison_results;
    assign o_tx_msg_valid    = wp_tx_valid | wp_rx_valid;

    // =====================================================
    // TX INSTANCE
    // =====================================================
    rx_initiated_point_test_tx #(
        .SB_MSG_WIDTH(SB_MSG_WIDTH)
    ) TX_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_rx_d2c_pt_en(i_rx_d2c_pt_en),
        .i_datavref_or_valvref(i_datavref_or_valvref),
        .i_pattern_finished(i_pattern_finished),
        .i_rx_msg_valid(i_rx_msg_valid),
        .i_decoded_SB_msg(i_decoded_SB_msg),

        .o_encoded_SB_msg_tx(wp_tx_encoded_SB_msg),
        .o_sb_data_pattern(sb_data_pattern),
        .o_sb_burst_count(sb_burst_count),
        .o_sb_comparison_mode(sb_comparison_mode),
        .o_clock_phase(sb_clock_phase),
        .o_valid_tx(wp_tx_valid),
        .o_val_pattern_en(o_val_pattern_en),
        .o_mainband_pattern_generator_cw(o_mainband_pattern_generator_cw),
        .o_rx_d2c_pt_done_tx(wp_rx_d2c_pt_done_tx)
    );

    // =====================================================
    // RX INSTANCE
    // =====================================================
    rx_initiated_point_test_rx #(
        .SB_MSG_WIDTH(SB_MSG_WIDTH)
    ) RX_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_rx_d2c_pt_en(i_rx_d2c_pt_en),
        .i_rx_msg_valid(i_rx_msg_valid),
        .i_decoded_SB_msg(i_decoded_SB_msg),
        .i_datavref_or_valvref(i_datavref_or_valvref),

        .o_encoded_SB_msg_rx(wp_rx_encoded_SB_msg),
        .o_valid_rx(wp_rx_valid),
        .o_comparison_valid_en(o_comparison_valid_en),
        .o_mainband_pattern_comparator_cw(o_mainband_pattern_comparator_cw),
        .o_rx_d2c_pt_done_rx(wp_rx_d2c_pt_done_rx)
    );

    // priority mux for sideband message
    always @(*) begin
        case ({wp_tx_valid, wp_rx_valid})
            2'b00: o_encoded_SB_msg = 4'b0000;
            2'b01: o_encoded_SB_msg = wp_rx_encoded_SB_msg;
            2'b10: o_encoded_SB_msg = wp_tx_encoded_SB_msg;
            2'b11: o_encoded_SB_msg = wp_rx_encoded_SB_msg;
            default: o_encoded_SB_msg = 4'b0000;
        endcase
    end

endmodule