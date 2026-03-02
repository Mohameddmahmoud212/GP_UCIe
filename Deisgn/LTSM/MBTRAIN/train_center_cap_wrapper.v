module train_center_cal_wrapper (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,

    // 0: VALTRAINCENTER, 1: DATATRAINCENTER1, 2: DATATRAINCENTER2

    // sideband decoded RX
    input  wire [3:0]  i_decoded_sideband_message,
    input  wire        i_sideband_valid,

    // arbitration/busy
    input  wire        i_busy_negedge_detected,

    // config
    input  wire        i_mainband_or_valtrain_test,
    input wire          i_lfsr_or_perlane ,
    // algo done + results from point-test
    input  wire        i_algo_done_ack,
    input  wire [15:0] i_tx_lanes_result,

    // outputs to sideband mux
    output wire [3:0]  o_sideband_message,
    output wire        o_valid,

    // point test enable (TX owns PT)
    output wire        o_pt_en,

    // forward test type (prefer TX when active)
    output wire        o_mainband_or_valtrain_test,

    // PI step out (TX owns PI)
    output wire [3:0]  o_pi_step,

    // split acks to mbtrain_controller
    output wire        o_traincenter_ack,

    // optional status/debug
    output wire        o_center_fail,
    output wire [15:0] o_center_lane_mask
);

    // TX nets
    wire [3:0]  sb_msg_tx;
    wire        valid_tx;
    wire        pt_en_tx;

    wire [3:0]  pi_step_tx;

    wire        ack_val_tx ;
    wire        fail_tx;
    wire [15:0] mask_tx;

    // RX nets
    wire [3:0]  sb_msg_rx;
    wire        valid_rx;

    wire        ack_val_rx ;

    // unified valid
    assign o_valid = valid_tx || valid_rx;

    // sideband message mux (TX priority)
    assign o_sideband_message =
        (valid_tx) ? sb_msg_tx :
        (valid_rx) ? sb_msg_rx :
                     4'b0000;

    // UPDATE #1: PT enable is TX responsibility only
    assign o_pt_en = pt_en_tx;

    // PI out from TX
    assign o_pi_step = pi_step_tx;

    // split ACKs (OR across TX/RX)
    assign o_traincenter_ack   = ack_val_tx && ack_val_rx;
    

    // status from TX (TX owns point-test + results)
    assign o_center_fail      = fail_tx;
    assign o_center_lane_mask = mask_tx;

    // TX instance
    train_center_cal_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_rx(valid_rx),

        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_algo_done_ack(i_algo_done_ack),

        .i_lfsr_or_perlane(i_lfsr_or_perlane),//
        .i_tx_lanes_result(i_tx_lanes_result),

        .o_sideband_message(sb_msg_tx),
        .o_valid_tx(valid_tx),

        .o_pt_en(pt_en_tx),
        .o_eye_width_sweep_en(o_eye_width_sweep_en),
        .o_pi_step(pi_step_tx),
        .o_mainband_or_valtrain_test(o_mainband_or_valtrain_test),
        .o_traincenter_ack(ack_val_tx),
        .o_vref_lane_mask(mask_tx),
        .o_vref_fail(fail_tx)
    );

    // RX instance
    train_center_cal_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_tx(valid_tx),
        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_lfsr_or_perlane(i_lfsr_or_perlane),

        // DONE from algo / point-test (same meaning as your i_test_ack)
        .i_algo_done_ack(i_algo_done_ack),

        // (optional) results bus (kept)
        .i_tx_lanes_result(i_tx_lanes_result),

        .o_sideband_message(sb_msg_rx),
        .o_valid_rx(valid_rx),
        .o_pt_en(o_pt_en),
        .o_eye_width_sweep_en(o_eye_width_sweep_en),

        .o_traincenter_ack(ack_val_rx)
        );

endmodule
