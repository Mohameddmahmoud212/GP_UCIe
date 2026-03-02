module selfcal_wrapper (
    //inputs
        input  wire       clk,
        input  wire       rst_n,
        input  wire       i_en,

        // NEW
        input  wire       i_selfcal_done_ack,  // NEW local done

        //communcating with sideband 
        input  wire [3:0] i_decoded_sideband_message,
        input  wire       i_sideband_valid,
        input  wire       i_busy_negedge_detected,

    //outputs 
        output wire [3:0] o_sideband_message,
        output wire       o_valid,

        // split ACKs (same naming as mbtrain_controller expects)
        output wire       o_self_cal_ack,
        output wire       o_test_en
);

    // TX nets
    wire [3:0] sb_msg_tx;
    wire       valid_tx;
    wire       ack_speed_tx, ack_txself_tx;

    // RX nets
    wire [3:0] sb_msg_rx;
    wire       valid_rx;
    wire       ack_self_tx, ack_self_rx;

    // unified valid
    assign o_valid = valid_tx || valid_rx;

    // sideband message mux (TX priority when it is driving)
    assign o_sideband_message =
        (valid_rx) ? sb_msg_rx :
        (valid_tx) ? sb_msg_tx :
                     4'b0000;

    // split ACK OR
    assign o_self_cal_ack = ack_self_tx || ack_self_rx;

    // TX
    selfcal_tx selfcal_tx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_rx(valid_rx),

        .i_selfcal_done_ack(i_selfcal_done_ack),

        .o_sideband_message(sb_msg_tx),
        .o_valid_tx(valid_tx),

        .o_tx_self_cal_ack(ack_self_tx),
        .o_test_en(o_test_en)
    );

    // RX
    selfcal_rx selfcal_rx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_tx(valid_tx),

        .i_selfcal_done_ack(i_selfcal_done_ack),

        .o_sideband_message(sb_msg_rx),
        .o_valid_rx(valid_rx),
        .o_rx_self_cal_ack(ack_self_rx),
        .o_test_en_rx(o_test_en_rx)
    );

endmodule