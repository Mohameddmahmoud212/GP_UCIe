module REPAIRVAL_Wrapper (
    input  wire         CLK,
    input  wire         rst_n,

    // Control / phase inputs
    input  wire         i_REPAIRCLK_end,

    // Pattern completion (modeled delay)
    input  wire         i_VAL_Pattern_done,

    // Sideband interface
    input  wire [3:0]   i_Rx_SbMessage,
    input  wire         i_msg_valid,
    input  wire         i_falling_edge_busy,

    // Result sources
    input  wire         i_VAL_Result_logged_RXSB, // result from RX sideband response
    input  wire         i_VAL_Result_logged_COMB, // result from comparator logic

    // Outputs
    output wire         o_train_error_req,
    output wire         o_MBINIT_REPAIRVAL_Pattern_En,
    output wire         o_MBINIT_REPAIRVAL_end,
    output wire [3:0]   o_TX_SbMessage,
    output wire         o_VAL_Result_logged,
    output wire         o_enable_cons,
    output wire         o_ValidOutDatatREPAIRVAL
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------

    // TX side
    wire        tx_valid;
    wire [3:0]  tx_sb_msg;
    wire        tx_done;
    wire        train_error_req;
    wire        pattern_en;

    // RX side
    wire        rx_valid;
    wire [3:0]  rx_sb_msg;
    wire        rx_done;
    wire        rx_result_logged;

    // -------------------------------------------------------------------------
    // REPAIRVAL TX Module
    // -------------------------------------------------------------------------
    REPAIRVAL_Module u1 (
        .CLK                        (CLK),
        .rst_n                      (rst_n),
        .i_REPAIRCLK_end            (i_REPAIRCLK_end),
        .i_VAL_Pattern_done         (i_VAL_Pattern_done),
        .i_Rx_SbMessage             (i_Rx_SbMessage),
        .i_Busy_SideBand            (rx_valid),          // RX owns SB when valid
        .i_falling_edge_busy        (i_falling_edge_busy),
        .i_msg_valid                (i_msg_valid),
        .i_VAL_Result_logged        (i_VAL_Result_logged_RXSB),

        .o_train_error_req          (train_error_req),
        .o_MBINIT_REPAIRVAL_Pattern_En (pattern_en),
        .o_MBINIT_REPAIRVAL_Module_end (tx_done),
        .o_TX_SbMessage             (tx_sb_msg),
        .o_ValidOutDatat_Module     (tx_valid)
    );

    // -------------------------------------------------------------------------
    // REPAIRVAL RX (Partner) Module
    // -------------------------------------------------------------------------
    REPAIRVAL_ModulePartner u2 (
        .CLK                        (CLK),
        .rst_n                      (rst_n),
        .i_REPAIRCLK_end            (i_REPAIRCLK_end),
        .i_VAL_Result_logged        (i_VAL_Result_logged_COMB),
        .i_Rx_SbMessage             (i_Rx_SbMessage),
        .i_falling_edge_busy        (i_falling_edge_busy),
        .i_Busy_SideBand            (tx_valid),          // TX owns SB when valid
        .i_msg_valid                (i_msg_valid),

        .o_VAL_Result_logged        (rx_result_logged),
        .o_TX_SbMessage             (rx_sb_msg),
        .o_MBINIT_REPAIRVAL_ModulePartner_end (rx_done),
        .o_ValidOutDatat_ModulePartner (rx_valid),
        .o_enable_cons              (o_enable_cons)
    );

    // -------------------------------------------------------------------------
    // Sideband arbitration
    // RX has priority over TX
    // -------------------------------------------------------------------------
    assign o_TX_SbMessage =
            rx_valid ? rx_sb_msg :
            tx_valid ? tx_sb_msg :
            4'b0000;

    // -------------------------------------------------------------------------
    // Outputs
    // -------------------------------------------------------------------------
    assign o_MBINIT_REPAIRVAL_end       = tx_done && rx_done;
    assign o_train_error_req            = train_error_req;
    assign o_MBINIT_REPAIRVAL_Pattern_En = pattern_en;
    assign o_VAL_Result_logged          = rx_result_logged;
    assign o_ValidOutDatatREPAIRVAL     = tx_valid || rx_valid;

endmodule
