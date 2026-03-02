module TRAINERROR_HS_WRAPPER #(
    parameter SB_MSG_WIDTH = 4
)(
    input                               i_clk,
    input                               i_rst_n,

    input                               i_trainerror_en,
    input                               i_rx_msg_valid,
    input   [SB_MSG_WIDTH-1:0]           i_decoded_SB_msg,

    output  reg [SB_MSG_WIDTH-1:0]        o_encoded_SB_msg,
    output                               o_TRAINERROR_HS_end,
    output                               o_tx_msg_valid
);

/////////////////////////////////////////
/////// INTERNAL WIRES FROM TX/RX ////////
/////////////////////////////////////////

wire wp_tx_valid;
wire wp_rx_valid;

wire [SB_MSG_WIDTH-1:0] wp_tx_encoded_SB_msg;
wire [SB_MSG_WIDTH-1:0] wp_rx_encoded_SB_msg;

wire wp_tx_end;
wire wp_rx_end;

/////////////////////////////////////////
/////////// INSTANTIATIONS //////////////
/////////////////////////////////////////

TX_TRAINERROR_HS #(
    .SB_MSG_WIDTH(SB_MSG_WIDTH)
) U_TX_TRAINERROR_HS (
    .i_clk               (i_clk),
    .i_rst_n             (i_rst_n),
    .i_trainerror_en      (i_trainerror_en),
    .i_rx_msg_valid       (i_rx_msg_valid),
    .i_decoded_SB_msg      (i_decoded_SB_msg),
    .o_encoded_SB_msg_tx    (wp_tx_encoded_SB_msg),
    .o_valid_tx             (wp_tx_valid),
    .o_trainerror_end_tx     (wp_tx_end)
);

RX_TRAINERROR_HS #(
    .SB_MSG_WIDTH(SB_MSG_WIDTH)
) U_RX_TRAINERROR_HS (
    .i_clk               (i_clk),
    .i_rst_n             (i_rst_n),
    .i_trainerror_en      (i_trainerror_en),
    .i_rx_msg_valid       (i_rx_msg_valid),
    .i_decoded_SB_msg      (i_decoded_SB_msg),
    .o_encoded_SB_msg_rx    (wp_rx_encoded_SB_msg),
    .o_valid_rx             (wp_rx_valid),
    .o_trainerror_end_rx     (wp_rx_end)
);

/////////////////////////////////////////
////// LATCHED HANDSHAKE COMPLETION ///////
/////////////////////////////////////////

reg tx_done_latched;
reg rx_done_latched;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        tx_done_latched <= 0;
        rx_done_latched <= 0;
    end
    else begin
        // latch completion pulses
        if (wp_tx_end)
            tx_done_latched <= 1;

        if (wp_rx_end)
            rx_done_latched <= 1;

        // clear when new session
        if (!i_trainerror_en) begin
            tx_done_latched <= 0;
            rx_done_latched <= 0;
        end
    end
end

assign o_TRAINERROR_HS_end = tx_done_latched & rx_done_latched;

/////////////////////////////////////////
////// SIDE-BAND VALIDITY ARBITRATION /////
/////////////////////////////////////////

assign o_tx_msg_valid = wp_tx_valid | wp_rx_valid;

always @(*) begin
    case ({wp_tx_valid, wp_rx_valid})

        2'b00: o_encoded_SB_msg = 4'b0000;

        2'b01: o_encoded_SB_msg = wp_rx_encoded_SB_msg;

        2'b10: o_encoded_SB_msg = wp_tx_encoded_SB_msg;

        2'b11:
            // RX wins priority if both valid (safe arbitration)
            o_encoded_SB_msg = wp_rx_encoded_SB_msg;

        default:
            o_encoded_SB_msg = 4'b0000;

    endcase
end



endmodule