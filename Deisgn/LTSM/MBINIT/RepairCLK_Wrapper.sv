// Wrapper module for REPAIRCLK_Module and RepairCLK_ModulePartner
// Coordinates main and partner FSMs, manages sideband arbitration

module RepairCLK_Wrapper (
    input wire          CLK,
    input wire          rst_n,
    input wire          i_MBINIT_CAL_end,
    input wire          i_CLK_Track_done,
    input wire [3:0]    i_Rx_SbMessage,
    input wire          i_falling_edge_busy,
    input wire          i_msg_valid,   
    input wire [2:0]    i_Clock_track_result_logged_RXSB, // from sideband
    input wire [2:0]    i_Clock_track_result_logged_COMB, // from comparator
    output          o_train_error_req,
    output          o_MBINIT_REPAIRCLK_Pattern_En,
    output          o_MBINIT_REPAIRCLK_end,
    output [3:0]    o_TX_SbMessage,
    output [2:0]    o_Clock_track_result_logged,
    output          o_clear_clk_detection,
    output          o_ValidOutDatatREPAIRCLK
);

    // Internal wires
    wire train_error_req;
    wire MBINIT_REPAIRCLK_Pattern_En;
    wire MBINIT_REPAIRCLK_Module_end;
    wire MBINIT_REPAIRCLK_ModulePartner_end;
    wire [3:0] TX_SbMessage_Module;
    wire [3:0] TX_SbMessage_ModulePartner;
    wire ValidOutDatat_Module;
    wire ValidOutDatat_ModulePartner;
    wire [2:0] Clock_track_result_logged;

    // Instantiate main module
    REPAIRCLK_Module u1 (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_CAL_end(i_MBINIT_CAL_end),
        .i_CLK_Track_done(i_CLK_Track_done),
        .i_Rx_SbMessage(i_Rx_SbMessage),
        .i_Busy_SideBand(ValidOutDatat_ModulePartner),
        .i_msg_valid(i_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_Clock_track_result_logged(i_Clock_track_result_logged_RXSB),
        .i_ValidOutDatat_ModulePartner(ValidOutDatat_ModulePartner),
        .o_train_error_req(train_error_req),
        .o_MBINIT_REPAIRCLK_Pattern_En(MBINIT_REPAIRCLK_Pattern_En),
        .o_MBINIT_REPAIRCLK_Module_end(MBINIT_REPAIRCLK_Module_end),
        .o_TX_SbMessage(TX_SbMessage_Module),
        .o_ValidOutDatat_Module(ValidOutDatat_Module)
    );

    // Instantiate partner module
    RepairCLK_ModulePartner u2 (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_CAL_end(i_MBINIT_CAL_end),
        .i_Clock_track_result_logged(i_Clock_track_result_logged_COMB),
        .i_msg_valid(i_msg_valid),
        .i_RX_SbMessage(i_Rx_SbMessage),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_Busy_SideBand(ValidOutDatat_Module),
        .o_Clock_track_result_logged(Clock_track_result_logged),
        .o_TX_SbMessage(TX_SbMessage_ModulePartner),
        .o_MBINIT_REPAIRCLK_ModulePartner_end(MBINIT_REPAIRCLK_ModulePartner_end),
        .o_ValidOutDatat_ModulePartner(ValidOutDatat_ModulePartner),
        .o_clear_clk_detection(o_clear_clk_detection)
    );

    // Output arbitration
    assign o_TX_SbMessage                  = ValidOutDatat_ModulePartner ? TX_SbMessage_ModulePartner :
                                             ValidOutDatat_Module ? TX_SbMessage_Module : 4'b0000;
    assign o_MBINIT_REPAIRCLK_end          = MBINIT_REPAIRCLK_Module_end && MBINIT_REPAIRCLK_ModulePartner_end;
    assign o_train_error_req               = train_error_req;
    assign o_MBINIT_REPAIRCLK_Pattern_En   = MBINIT_REPAIRCLK_Pattern_En;
    assign o_Clock_track_result_logged     = Clock_track_result_logged;
    assign o_ValidOutDatatREPAIRCLK        = ValidOutDatat_ModulePartner || ValidOutDatat_Module;

endmodule
