module REPAIRMB_Wrapper (
    input                   CLK,
    input                   rst_n,
    input                   MBINIT_REVERSALMB_end,
    input [3:0]             i_RX_SbMessage,
    input                   i_falling_edge_busy,
    input                   i_Transmitter_initiated_Data_to_CLK_done,
    input [15:0]            i_Transmitter_initiated_Data_to_CLK_Result,
    input [1:0]             i_Functional_Lanes, 
    input                   i_msg_valid,
   
    output  [3:0]           o_TX_SbMessage,
    output                  o_MBINIT_REPAIRMB_end,
    output                  o_ValidOutDatat_REPAIRMB,
  
    output  [1:0]           o_Functional_Lanes_out_tx,
    output  [1:0]           o_Functional_Lanes_out_rx,
    output                  o_Transmitter_initiated_Data_to_CLK_en,
    output                  o_perlane_Transmitter_initiated_Data_to_CLK,
    output                  o_mainband_Transmitter_initiated_Data_to_CLK,
  
    output                  o_train_error,
    output  [2:0]           o_msg_info_repairmb 
);

    // ----------------------------
    // Internal wires
    // ----------------------------
    // TX module signals
    wire [3:0]  TX_SbMessage_Module;
    wire        MBINIT_REPAIRMB_Module_end;
    wire        ValidOutDatat_Module;
    wire [1:0]  Functional_Lanes_Module;

    // Partner (RX) module signals
    wire [3:0]  TX_SbMessage_ModulePartner;
    wire        MBINIT_REPAIRMB_ModulePartner_end;
    wire        ValidOutDatat_ModulePartner;
    wire [1:0]  Functional_Lanes_ModulePartner;
    wire        train_error_ModulePartner;

    // Handshake signals between TX and Partner
    wire        Start_Repeater;
    wire        Done_Repeater;
    wire        apply_repeater;

    // ----------------------------
    // Instantiate REPAIRMB_Module (TX)
    // ----------------------------
    REPAIRMB_Module REPAIRMB_Module_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .MBINIT_REVERSALMB_end(MBINIT_REVERSALMB_end),
        .i_RX_SbMessage(i_RX_SbMessage),
        .i_Busy_SideBand(ValidOutDatat_ModulePartner),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_msg_valid(i_msg_valid),
        .i_Start_Repeater(Start_Repeater),
        .i_Transmitter_initiated_Data_to_CLK_done(i_Transmitter_initiated_Data_to_CLK_done),
        .i_Transmitter_initiated_Data_to_CLK_Result(i_Transmitter_initiated_Data_to_CLK_Result),
        .apply_repeater(apply_repeater),
        .o_TX_SbMessage(TX_SbMessage_Module),
        .o_Done_Repeater(Done_Repeater),
        .o_MBINIT_REPAIRMB_Module_end(MBINIT_REPAIRMB_Module_end),
        .o_ValidOutDatat_REPAIRMB_Module(ValidOutDatat_Module),
        .o_Functional_Lanes(Functional_Lanes_Module),
        .o_Transmitter_initiated_Data_to_CLK_en(o_Transmitter_initiated_Data_to_CLK_en),
        .o_perlane_Transmitter_initiated_Data_to_CLK(o_perlane_Transmitter_initiated_Data_to_CLK),
        .o_mainband_Transmitter_initiated_Data_to_CLK(o_mainband_Transmitter_initiated_Data_to_CLK),
        .o_msg_info_repairmb(o_msg_info_repairmb)
    );

    // ----------------------------
    // Instantiate REPAIRMB_Module_Partner (RX)
    // ----------------------------
    REPAIRMB_Module_Partner REPAIRMB_Module_Partner_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .MBINIT_REVERSALMB_end(MBINIT_REVERSALMB_end),
        .i_Busy_SideBand(ValidOutDatat_Module),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_RX_SbMessage(i_RX_SbMessage),
        .i_msg_valid(i_msg_valid),
        .i_Functional_Lanes(i_Functional_Lanes),
        .i_Transmitter_initiated_Data_to_CLK_en(o_Transmitter_initiated_Data_to_CLK_en),
        .i_Done_Repeater(Done_Repeater),
        .o_Start_Repeater(Start_Repeater),
        .o_train_error(train_error_ModulePartner),
        .o_MBINIT_REPAIRMB_Module_Partner_end(MBINIT_REPAIRMB_ModulePartner_end),
        .o_ValidOutDatat_REPAIRMB_Module_Partner(ValidOutDatat_ModulePartner),
        .o_TX_SbMessage(TX_SbMessage_ModulePartner),
        .o_Functional_Lanes(Functional_Lanes_ModulePartner),
        .apply_repeater(apply_repeater)
    );

    // ----------------------------
    // Combinational output logic
    // ----------------------------
    assign o_TX_SbMessage               = ValidOutDatat_ModulePartner ? TX_SbMessage_ModulePartner : 
                                          ValidOutDatat_Module ? TX_SbMessage_Module : 4'b0000;

    assign o_MBINIT_REPAIRMB_end        = MBINIT_REPAIRMB_Module_end && MBINIT_REPAIRMB_ModulePartner_end;
    assign o_ValidOutDatat_REPAIRMB     = ValidOutDatat_ModulePartner || ValidOutDatat_Module;
    assign o_Functional_Lanes_out_tx    = Functional_Lanes_Module;
    assign o_Functional_Lanes_out_rx    = Functional_Lanes_ModulePartner;
    assign o_train_error                = train_error_ModulePartner;

endmodule
