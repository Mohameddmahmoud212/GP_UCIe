module vref_cal_wrapper (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,

    input  wire [3:0]  i_decoded_sideband_message,
    input  wire        i_sideband_valid,

    input  wire        i_busy_negedge_detected,

    input  wire        i_algo_done_ack,       // for TX
    input  wire        i_test_ack,            // for RX
    input  wire [15:0] i_rx_lanes_result,

    input  wire        i_mainband_or_valtrain_test, // used by RX (VALVREF => set 1)
    input  [3:0]       i_reciever_ref_voltage ,
    output wire [3:0]  o_sideband_message,
    output wire        o_valid,

    output wire        o_pt_en,
    output wire        o_mainband_or_valtrain_test,

    output wire        o_valvref_done,

    output wire        o_valvref_fail,
    output wire [15:0] o_valvref_lane_mask,

    output wire [3:0]  o_reciever_ref_voltage
);

    // TX nets
    wire [3:0]  sb_msg_tx;
    wire        valid_tx;
    wire        pt_en_tx;
    wire        ack_tx;
    wire        fail_tx;
    wire [15:0] mask_tx;

    // RX nets
    wire [3:0]  sb_msg_rx;
    wire        valid_rx;
    wire        pt_en_rx;
    wire [3:0]  vref_word_rx;
    wire        ack_rx;
    wire        fail_rx;
    wire [15:0] mask_rx;

    // unified valid
    assign o_valid = valid_tx || valid_rx;

    // sideband message mux (TX priority)
    assign o_sideband_message =
        (valid_tx) ? sb_msg_tx :
        (valid_rx) ? sb_msg_rx :
                     4'b0000;

    // PT enable
    assign o_pt_en = pt_en_tx || pt_en_rx;

    // ack back to controller
    assign o_valvref_done = ack_tx && ack_rx;

    // status chosen by who acked
    assign o_valvref_fail =
        (ack_tx) ? fail_tx :
        (ack_rx) ? fail_rx :
                  fail_tx;

    assign o_valvref_lane_mask =
        (ack_tx) ? mask_tx :
        (ack_rx) ? mask_rx :
                  mask_tx;

    // analog word is RX responsibility
    assign o_reciever_ref_voltage = vref_word_rx;

    // ---------------- TX instance (MATCHES YOUR TX PORTS) ----------------
    vref_cal_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),
        
        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_rx(valid_rx),

        .i_algo_done_ack(i_algo_done_ack),
        .i_rx_lanes_result(i_rx_lanes_result),

        .o_sideband_message(sb_msg_tx),
        .o_valid_tx(valid_tx),

        .o_pt_en(pt_en_tx),
        .o_mainband_or_valtrain_test(mode_tx),

        .o_vref_ack(ack_tx),
        .o_vref_fail(fail_tx),
        .o_vref_lane_mask(mask_tx)
    );

    // ---------------- RX instance (MATCHES YOUR RX PORTS) ----------------
    vref_cal_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_tx(valid_tx),
        .i_pattern_detected(i_algo_done_ack),
        .i_reciever_ref_voltage(i_reciever_ref_voltage),

        .i_rx_lanes_result(i_rx_lanes_result),

        .o_sideband_message(sb_msg_rx),
        .o_valid_rx(valid_rx),

        .o_pt_en(pt_en_rx),
        .o_reciever_ref_voltage(vref_word_rx),
        .o_mainband_or_valtrain_test(o_mainband_or_valtrain_test),
        .o_vref_ack(ack_rx),

        .o_vref_fail(fail_rx),
        .o_vref_lane_mask(mask_rx)
    );

endmodule
