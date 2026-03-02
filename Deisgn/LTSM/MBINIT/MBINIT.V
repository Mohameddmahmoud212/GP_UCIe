`timescale 1ns/1ps
module MBINIT (
    input               CLK,
    input               rst_n,
    input               i_MBINIT_Start_en,
    input [3:0]         i_rx_msg_no,
    input [15:0]        i_rx_data_bus,
    input [2:0]         i_rx_msg_info,
    input               i_rx_busy,
  
    input               i_falling_edge_busy,
    input               i_msg_valid,
    input               i_REVERSAL_done,  // from the block which prepare the reversal 
    input               i_CLK_Track_done,
    input               i_VAL_Pattern_done,
    input               i_LaneID_Pattern_done,    //from REVERSALMB_Wrapper
    input   [2:0]       i_logged_clk_result,      // i_Clock_track_result_logged from comparator after detection clk pattern
    input               i_logged_val_result,      // i_VAL_Result_logged from comparator after detection val pattern
    input   [15:0]      i_logged_lane_id_result,    // i_REVERSAL_Result_logged from comparator after detection reversal pattern
    input               i_Transmitter_initiated_Data_to_CLK_done,  // from tx initiated after done test
    input   [15:0]      i_Transmitter_initiated_Data_to_CLK_Result,  // from tx initiated after done test

    output  [3:0]       o_tx_sub_state,
    output  [3:0]       o_tx_msg_no,
    output  [15:0]      o_tx_data_bus,  // data field parameters (param) , 16 bits for results of the lanes (reversalmb)
    output  [2:0]       o_tx_msg_info,  // repair clk(results for clkn ,clkp,track) , repair val ,repair mb (functional lanes)
    output              o_tx_msg_valid,
    output              o_tx_data_valid,
    output              o_MBINIT_REPAIRCLK_Pattern_En, // send to the CLK_PATTERN_GENERATOR to send clk pattern
    output              o_MBINIT_REPAIRVAL_Pattern_En, // send to the VAL_PATTERN_GENERATOR to send val pattern
    output  [1:0]       o_MBINIT_REVERSALMB_LaneID_Pattern_En,  // send to the REVERSALMB to send lane id pattern
    output              o_MBINIT_REVERSALMB_ApplyReversal_En,  // send to the REVERSALMB to apply reversal pattern
    output  [1:0]       o_Clear_Pattern_Comparator, // clear the comparator
    output  [1:0]       o_Functional_Lanes_out_tx,
    output  [1:0]       o_Functional_Lanes_out_rx,
    output              o_Transmitter_initiated_Data_to_CLK_en,
    output              o_perlane_Transmitter_initiated_Data_to_CLK,  // send to the point test
    output              o_mainband_Transmitter_initiated_Data_to_CLK, // send to the point test
    output [2:0]        o_Final_MaxDataRate,  //For MBTRAIN 
    output              o_Final_ClockMode,
    output              o_Final_ClockPhase,
    output              o_train_error_req,
    output              o_enable_cons,
    output              o_clear_clk_detection,  // for clk_detection to clear its result for detect another one
    output              o_Finish_MBINIT
);

    // ------------------------
    // MBINIT FSM Signals
    // ------------------------
    wire param_start, cal_start, repairclk_start, repairval_start, reversalmb_start, repairmb_start;

    // ------------------------
    // Wrapper End Signals
    // ------------------------
    wire MBINIT_PARAM_end, MBINIT_CAL_end, MBINIT_REPAIRCLK_end, MBINIT_REPAIRVAL_end;
    wire MBINIT_REVERSALMB_end, MBINIT_REPAIRMB_end;

    // ------------------------
    // Wrapper Valid & Data Signals
    // ------------------------
    wire o_tx_msg_valid_param, o_tx_msg_valid_CAL, o_tx_msg_valid_REPAIRCLK;
    wire o_tx_msg_valid_REPAIRVAL, o_tx_msg_valid_REVERSALMB, o_tx_msg_valid_REPAIRMB;

    wire [3:0] o_tx_msg_no_param, o_tx_msg_no_cal, o_tx_msg_no_repairclk;
    wire [3:0] o_tx_msg_no_repairval, o_tx_msg_no_reversalmb, o_tx_msg_no_repairmb;

    wire [9:0] o_tx_data_bus_param;
    wire [15:0] o_tx_data_bus_reversalmb;
    wire o_tx_data_valid_param, o_tx_data_valid_reversalmb;

    wire [2:0] o_tx_msg_info_repairclk;
    wire o_tx_msg_info_repairval;
    wire [2:0] o_msg_info_repairmb;

    wire train_error_req_param, train_error_req_repairclk;
    wire train_error_req_repairval, train_error_req_repairmb;
    wire o_train_error_req_reversalmb;

    wire [1:0] Functional_Lanes_out_tx, Functional_Lanes_out_rx;

    // ------------------------
    // MBINIT FSM
    // ------------------------
    MBINIT_FSM mbinit_fsm_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_Start_en(i_MBINIT_Start_en),
        .i_PARAM_end(MBINIT_PARAM_end),
        .i_CAL_end(MBINIT_CAL_end),
        .i_REPAIRCLK_end(MBINIT_REPAIRCLK_end),
        .i_REPAIRVAL_end(MBINIT_REPAIRVAL_end),
        .i_REVERSALMB_end(MBINIT_REVERSALMB_end),
        .i_REPAIRMB_end(MBINIT_REPAIRMB_end),
        .o_PARAM_start(param_start),
        .o_CAL_start(cal_start),
        .o_REPAIRCLK_start(repairclk_start),
        .o_REPAIRVAL_start(repairval_start),
        .o_REVERSALMB_start(reversalmb_start),
        .o_REPAIRMB_start(repairmb_start),
        .o_Finish_MBINIT(o_Finish_MBINIT)
    );

    // ------------------------
    // PARAM Wrapper
    // ------------------------
    PARAM_Wrapper PARAM_Wrapper_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_Start_en(param_start),
        .i_RX_SbMessage(i_rx_msg_no),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_MaxDataRate(i_rx_data_bus[2:0]),
        .i_TX_VoltageSwing(i_rx_data_bus[7:3]),
        .i_RX_ClockMode(i_rx_data_bus[8]),
        .i_RX_PhaseClock(i_rx_data_bus[9]),
        .i_msg_valid(i_msg_valid),
        .o_MaxDataRate(o_tx_data_bus_param[2:0]),
        .o_TX_VoltageSwing(o_tx_data_bus_param[7:3]),
        .o_TX_ClockMode(o_tx_data_bus_param[8]),
        .o_TX_PhaseClock(o_tx_data_bus_param[9]),
        .o_MBINIT_PARAM_end(MBINIT_PARAM_end),
        .o_ValidOutDatat_Module(o_tx_msg_valid_param),
        .o_ValidDataFieldParameters(o_tx_data_valid_param),
        .o_train_error_req(train_error_req_param),
        .o_TX_SbMessage(o_tx_msg_no_param),
        .o_Final_MaxDataRate(o_Final_MaxDataRate),
        .o_Final_ClockMode(o_Final_ClockMode),
        .o_Final_ClockPhase(o_Final_ClockPhase)
    );

    // ------------------------
    // CAL Wrapper
    // ------------------------
    CAL_ModuleWrapper CAL_ModuleWrapper_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_PARAM_end(cal_start),
       
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_RX_SbMessage(i_rx_msg_no),
        .i_msg_valid(i_msg_valid),
        .o_TX_SbMessage(o_tx_msg_no_cal),
        .o_ValidOutDatatCAL(o_tx_msg_valid_CAL),
        .o_MBINIT_CAL_end(MBINIT_CAL_end)
    );

    // ------------------------
    // REPAIRCLK Wrapper
    // ------------------------
    RepairCLK_Wrapper RepairCLK_Wrapper_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_CAL_end(repairclk_start),
        .i_CLK_Track_done(i_CLK_Track_done),
        .i_Rx_SbMessage(i_rx_msg_no),
        .i_msg_valid(i_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_Clock_track_result_logged_RXSB(i_rx_msg_info),
        .i_Clock_track_result_logged_COMB(i_logged_clk_result),
        .o_train_error_req(train_error_req_repairclk),
        .o_MBINIT_REPAIRCLK_Pattern_En(o_MBINIT_REPAIRCLK_Pattern_En),
        .o_MBINIT_REPAIRCLK_end(MBINIT_REPAIRCLK_end),
        .o_Clock_track_result_logged(o_tx_msg_info_repairclk),
        .o_TX_SbMessage(o_tx_msg_no_repairclk),
        .o_clear_clk_detection(o_clear_clk_detection),
        .o_ValidOutDatatREPAIRCLK(o_tx_msg_valid_REPAIRCLK)
    );

    // ------------------------
    // REPAIRVAL Wrapper
    // ------------------------
    REPAIRVAL_Wrapper REPAIRVAL_Wrapper_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_REPAIRCLK_end(repairval_start),
        .i_VAL_Pattern_done(i_VAL_Pattern_done),
        .i_Rx_SbMessage(i_rx_msg_no),
        .i_msg_valid(i_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_VAL_Result_logged_RXSB(i_rx_msg_info[0]),
        .i_VAL_Result_logged_COMB(i_logged_val_result),
        .o_train_error_req(train_error_req_repairval),
        .o_MBINIT_REPAIRVAL_Pattern_En(o_MBINIT_REPAIRVAL_Pattern_En),
        .o_MBINIT_REPAIRVAL_end(MBINIT_REPAIRVAL_end),
        .o_TX_SbMessage(o_tx_msg_no_repairval),
        .o_VAL_Result_logged(o_tx_msg_info_repairval),
        .o_ValidOutDatatREPAIRVAL(o_tx_msg_valid_REPAIRVAL),
        .o_enable_cons(o_enable_cons)
    );

    // ------------------------
    // REVERSALMB Wrapper
    // ------------------------
    REVERSALMB_Wrapper REVERSALMB_Wrapper_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_REPAIRVAL_end(reversalmb_start),
        .i_Rx_SbMessage(i_rx_msg_no),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_REVERSAL_done(i_REVERSAL_done),
        .i_msg_valid(i_msg_valid),
        .i_LaneID_Pattern_done(i_LaneID_Pattern_done),
        .i_REVERSAL_Result_logged_RXSB(i_rx_data_bus),
        .i_REVERSAL_Result_logged_COMB(i_logged_lane_id_result),
        .o_MBINIT_REVERSALMB_LaneID_Pattern_En(o_MBINIT_REVERSALMB_LaneID_Pattern_En),
        .o_MBINIT_REVERSALMB_ApplyReversal_En(o_MBINIT_REVERSALMB_ApplyReversal_En),
        .o_MBINIT_REVERSALMB_end(MBINIT_REVERSALMB_end),
        .o_TX_SbMessage(o_tx_msg_no_reversalmb),
        .o_Clear_Pattern_Comparator(o_Clear_Pattern_Comparator),
        .o_REVERSAL_Pattern_Result_logged(o_tx_data_bus_reversalmb),
        .o_ValidOutDatatREVERSALMB(o_tx_msg_valid_REVERSALMB),
        .o_ValidDataFieldParameters(o_tx_data_valid_reversalmb),
        .o_train_error_req_reversalmb(o_train_error_req_reversalmb)
    );

    // ------------------------
    // REPAIRMB Wrapper
    // ------------------------
    REPAIRMB_Wrapper REPAIRMB_Wrapper_inst (
        .CLK(CLK),
        .rst_n(rst_n),
        .MBINIT_REVERSALMB_end(repairmb_start),
        .i_RX_SbMessage(i_rx_msg_no),
        .i_msg_valid(i_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_Transmitter_initiated_Data_to_CLK_done(i_Transmitter_initiated_Data_to_CLK_done),
        .i_Transmitter_initiated_Data_to_CLK_Result(i_Transmitter_initiated_Data_to_CLK_Result),
        .i_Functional_Lanes(i_rx_msg_info[1:0]),
        .o_TX_SbMessage(o_tx_msg_no_repairmb),
        .o_MBINIT_REPAIRMB_end(MBINIT_REPAIRMB_end),
        .o_ValidOutDatat_REPAIRMB(o_tx_msg_valid_REPAIRMB),
        .o_Functional_Lanes_out_tx(Functional_Lanes_out_tx),
        .o_Functional_Lanes_out_rx(Functional_Lanes_out_rx),
        .o_Transmitter_initiated_Data_to_CLK_en(o_Transmitter_initiated_Data_to_CLK_en),
        .o_perlane_Transmitter_initiated_Data_to_CLK(o_perlane_Transmitter_initiated_Data_to_CLK),
        .o_mainband_Transmitter_initiated_Data_to_CLK(o_mainband_Transmitter_initiated_Data_to_CLK),
        .o_train_error(train_error_req_repairmb),
        .o_msg_info_repairmb(o_msg_info_repairmb)
    );



    // ------------------------
    // Top-level output arbitration
    // ------------------------
    assign o_tx_msg_no = (param_start) ? o_tx_msg_no_param :
                         (cal_start) ? o_tx_msg_no_cal :
                         (repairclk_start) ? o_tx_msg_no_repairclk :
                         (repairval_start) ? o_tx_msg_no_repairval :
                         (reversalmb_start) ? o_tx_msg_no_reversalmb :
                         (repairmb_start) ? o_tx_msg_no_repairmb : 4'b0000;

    assign o_tx_data_bus = (param_start) ? {{6{1'b0}}, o_tx_data_bus_param[9:0]} :
                           (reversalmb_start) ? o_tx_data_bus_reversalmb : 16'b0;

    assign o_tx_msg_info = (param_start) ? 3'b000 :
                           (repairclk_start) ? o_tx_msg_info_repairclk :
                           (repairval_start) ? {2'b00, o_tx_msg_info_repairval} :
                           o_msg_info_repairmb;

    
    assign o_tx_sub_state = (param_start) ? 4'b0000 :
                            (cal_start) ? 4'b0001 :
                            (repairclk_start) ? 4'b0010 :
                            (repairval_start) ? 4'b0011 :
                            (reversalmb_start) ? 4'b0100 :
                            (repairmb_start) ? 4'b0101 : 4'b0000;

    assign o_Functional_Lanes_out_tx = Functional_Lanes_out_tx;
    assign o_Functional_Lanes_out_rx = Functional_Lanes_out_rx;

    assign o_tx_msg_valid = o_tx_msg_valid_param || o_tx_msg_valid_CAL || o_tx_msg_valid_REPAIRCLK ||
                            o_tx_msg_valid_REPAIRVAL || o_tx_msg_valid_REVERSALMB || o_tx_msg_valid_REPAIRMB;

    assign o_tx_data_valid = o_tx_data_valid_param || o_tx_data_valid_reversalmb;

    assign o_train_error_req = train_error_req_param || train_error_req_repairclk || train_error_req_repairval ||
                               train_error_req_repairmb || o_train_error_req_reversalmb;

endmodule
