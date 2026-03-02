module rx_cal_wrapper (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,

    input  wire       i_rx_cal_done_ack,

    input  wire [3:0] i_decoded_sideband_message,
    input  wire       i_sideband_valid,

    input  wire       i_busy_negedge_detected,

    output wire [3:0] o_sideband_message,
    output wire       o_valid,
    output wire        o_rx_cal_en,
    output wire       o_rx_cal_ack
);

    // TX nets
    wire [3:0] sb_msg_tx;
    wire       valid_tx;
    wire       ack_clk_tx, ack_dsk_tx;
    wire       pt_en_tx ,pt_en_rx ;
    
    // RX nets
    wire [3:0] sb_msg_rx;
    wire       valid_rx;
    wire       ack_clk_rx, ack_dsk_rx;

    assign o_valid = valid_tx || valid_rx;
    assign o_rx_cal_en = pt_en_tx || pt_en_rx ;
    // RX priority
    assign o_sideband_message =
        (valid_rx) ? sb_msg_rx :
        (valid_tx) ? sb_msg_tx :
                     4'b0000;

    assign o_rx_cal_ack = ack_clk_tx || ack_clk_rx;

    rx_cal_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),


        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_rx(valid_rx),

        .i_rx_cal_done_ack(i_rx_cal_done_ack),

        .o_sideband_message(sb_msg_tx),
        .o_valid_tx(valid_tx),
        .o_rx_cal_en(pt_en_tx),
        .o_rx_cal_ack(ack_clk_tx)
    );

    rx_cal_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_valid_tx(valid_tx),

        .i_rx_cal_done_ack(i_rx_cal_done_ack),

        .o_sideband_message(sb_msg_rx),
        .o_valid_rx(valid_rx),
        .o_rx_cal_en(pt_en_rx),
        .o_rx_cal_ack(ack_clk_rx)
    );

endmodule