module PHYRETRAIN_WRAPPER #(
    parameter SB_MSG_WIDTH = 4
)(    
    input                       i_clk,
    input                       i_rst_n,

    // LTSM related signals
    input                       i_PHYRETRAIN_en,
    input                       i_enter_from_active_or_mbtrain, // 0: from ACTIVE, 1: from MBTRAIN.LINKSPEED
    input       [1:0]           i_link_status,       // lane status from linkspeed
    input                       i_reset_resolved_state, // clear resolved_state before a new training

    // from SB
    input                           i_sb_busy,          // 1: SB busy, 0: SB ready
    input                           i_rx_msg_valid,     // SB received a message this cycle (decoded_msg valid)
    input       [SB_MSG_WIDTH-1:0]  i_decoded_SB_msg,// decoded SB message from partner
    input       [2:0]               i_rx_msg_info,      // partner retrain encoding (TXSELFCAL/REPAIR/SPEEDIDLE)

    // To SB
    output  reg [SB_MSG_WIDTH-1:0] o_encoded_SB_msg, 
    output  reg                    o_tx_msg_valid,   // selected valid (TX or RX)
    output      [2:0]              o_tx_msg_info,    // local retrain encoding (from TX)

    // To LTSM
    output                         o_PHYRETRAIN_end, // both TX and RX finished PHYRETRAIN
    output      [2:0]              o_resolved_state  // resolved next state from RX
);

    // Internal wires between wrapper & TX/RX

    // TX side
    wire [SB_MSG_WIDTH-1:0] wp_tx_encoded_SB_msg;
    wire [2:0]              wp_tx_msg_info;
    wire                    wp_tx_valid;
    wire                    wp_tx_PHYRETRAIN_end;

    // RX side
    wire [SB_MSG_WIDTH-1:0] wp_rx_encoded_SB_msg;
    wire [2:0]              wp_rx_resolved_state;
    wire                    wp_rx_valid;
    wire                    wp_rx_PHYRETRAIN_end;

    // Ready signals from wrapper to TX/RX (Option A)
    wire w_tx_ready_tx;
    wire w_tx_ready_rx;

    // SB ready
    wire sb_ready = ~i_sb_busy;

    /////////////////////////////////////////
    // Instantiation of TX_PHYRETRAIN
    /////////////////////////////////////////
    tx_phyretrain #(
        .SB_MSG_WIDTH(SB_MSG_WIDTH)
    ) U_TX_PHYRETRAIN (
        .i_clk                      (i_clk),
        .i_rst_n                    (i_rst_n),
        .i_PHYRETRAIN_en            (i_PHYRETRAIN_en),
        .i_tx_ready_tx              (w_tx_ready_tx),      // from wrapper
        .i_rx_msg_valid             (i_rx_msg_valid),
        .i_decoded_SB_msg           (i_decoded_SB_msg),
        .i_enter_from_active_or_mbtrain (i_enter_from_active_or_mbtrain),
        .i_link_status              (i_link_status),
        .i_sb_busy                  (i_sb_busy),
        .o_encoded_SB_msg_tx        (wp_tx_encoded_SB_msg),
        .o_msg_info                 (wp_tx_msg_info),
        .o_valid_tx                 (wp_tx_valid),
        .o_PHYRETRAIN_end_tx        (wp_tx_PHYRETRAIN_end)
    );

    // Instantiation of RX_PHYRETRAIN
    rx_phyretrain #(
        .SB_MSG_WIDTH(SB_MSG_WIDTH)
    ) U_RX_PHYRETRAIN (
        .i_clk                      (i_clk),
        .i_rst_n                    (i_rst_n),
        .i_PHYRETRAIN_en            (i_PHYRETRAIN_en),
        .i_reset_resolved_state     (i_reset_resolved_state),
        .i_tx_ready_rx              (w_tx_ready_rx),         // from wrapper
        .i_local_retrain_encoding   (wp_tx_msg_info),        // local encoding from TX
        .i_rx_msg_valid             (i_rx_msg_valid),
        .i_decoded_SB_msg           (i_decoded_SB_msg),
        .i_sb_busy                  (i_sb_busy),
        .i_die_retrain_encoding     (i_rx_msg_info),         // encoding from partner via SB
        .o_encoded_SB_msg_rx        (wp_rx_encoded_SB_msg),
        .o_resolved_state           (wp_rx_resolved_state),
        .o_valid_rx                 (wp_rx_valid),
        .o_PHYRETRAIN_end_rx        (wp_rx_PHYRETRAIN_end)
    );

    /////////////////////////////////////////
    // Arbitration (RX priority, Option A)
    /////////////////////////////////////////

    // grant encoding: 00 - none, 01 - TX, 10 - RX
    reg [1:0] grant;

    localparam GRANT_NONE = 2'b00;
    localparam GRANT_TX   = 2'b01;
    localparam GRANT_RX   = 2'b10;

    wire grant_tx = (grant == GRANT_TX);
    wire grant_rx = (grant == GRANT_RX);

    // fire when granted side has valid and SB is ready
    wire fire_tx   = grant_tx && wp_tx_valid && sb_ready;
    wire fire_rx   = grant_rx && wp_rx_valid && sb_ready;
    wire fire_any  = fire_tx | fire_rx;

    // Grant logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            grant <= GRANT_NONE;
        end else begin
            if (!i_PHYRETRAIN_en) begin
                grant <= 2'b00;
            end else begin
                if (grant == 2'b00) begin
                    // choose new grant - RX has priority
                    if (wp_rx_valid)
                        grant <= 2'b10;
                    else if (wp_tx_valid)
                        grant <= 2'b01;
                    else
                        grant <= 2'b00;
                end else begin
                    // hold grant until message is accepted (fire_any)
                    if (fire_any)
                        grant <= 2'b00;
                end
            end
        end
    end

    // Ready back to TX/RX (Option A)
    assign w_tx_ready_tx = grant_tx && sb_ready;
    assign w_tx_ready_rx = grant_rx && sb_ready;

    
    // Drive outputs to SB (encoded msg + valid)
    always @(*) begin
        if (grant_rx) begin
            o_encoded_SB_msg = wp_rx_encoded_SB_msg;
            o_tx_msg_valid   = wp_rx_valid;
        end else if (grant_tx) begin
            o_encoded_SB_msg = wp_tx_encoded_SB_msg;
            o_tx_msg_valid   = wp_tx_valid;
        end else begin
            o_encoded_SB_msg = {SB_MSG_WIDTH{1'b0}};
            o_tx_msg_valid   = 1'b0;
        end
    end

    // TX encodes the retrain decision; SB & RX use it
    assign o_tx_msg_info   = wp_tx_msg_info;

    // PHYRETRAIN_end handling (TX & RX pulses)

    reg tx_done_seen;
    reg rx_done_seen;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            tx_done_seen <= 1'b0;
            rx_done_seen <= 1'b0;
        end else begin
            if (!i_PHYRETRAIN_en) begin
                // new sequence => clear flags
                tx_done_seen <= 1'b0;
                rx_done_seen <= 1'b0;
            end else begin
                if (wp_tx_PHYRETRAIN_end) tx_done_seen <= 1'b1;
                if (wp_rx_PHYRETRAIN_end) rx_done_seen <= 1'b1;
            end
        end
    end

    assign o_PHYRETRAIN_end = tx_done_seen & rx_done_seen;

    // resolved state is decided in RX
    assign o_resolved_state = wp_rx_resolved_state;

endmodule
