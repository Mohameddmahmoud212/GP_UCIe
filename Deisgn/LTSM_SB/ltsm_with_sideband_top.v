module ltsm_with_sideband_top(

    input i_clk,
    input i_rst_n,
    ///// input for sideband 
    input i_tx_point_sweep_test_en,
    input [1:0]i_tx_point_sweep_test,
    input RXCKSB,
    input RXDATASB,
    input i_pattern_detected ,
    ///// ouput for sideband 
    output TXDATASB,
    output o_pattern_time_out,
    output TXCKSB,
    output o_tx_point_sweep_test_en,
    output [1:0] o_tx_point_sweep_test,
    /// ltsm 
   
    input           i_lp_linkerror,
    input           i_start_training_rdi,       // from rdi means that our die start send pattern , rdi not implemented yet 
    input           i_go_to_phyretrain_ACTIVE,  //
    input [3:0]     i_reciever_ref_voltage ,        // handle in test bench 

    /////////////////////////////////////////////////
    input i_tx_point_test_ack,
    input i_rx_point_test_ack,

    input [15:0] i_tx_lanes_result,
    input [15:0] i_rx_lanes_result,

    input i_selfcal_done_ack,
    input i_rx_cal_done_ack,
    input i_reset_resolved_state,
    input           i_time_out,                 //time out for the sb pattern  (o_pattern_time_out)
    input           i_start_receiving_pattern,
    input           i_start_pattern_done,       //*******ML DIE ELTANYA EN EL SBINIT 3NDHA KHLST W DE OUTPUT ML SB_WRAPPER*********
    ///////////////////////////////
    //////ltsm  and does not make 
    ////////////////
    input          i_ACTIVE_DONE ,
    input          i_LINKINIT_DONE,             // lisa ma7didnash hani3ml fe eh 
    ////////////////////////////
    /////piont test module 
    /////////////////////////
    input               i_Transmitter_initiated_Data_to_CLK_done,   // from tx initiated after done test
    input   [15:0]      i_Transmitter_initiated_Data_to_CLK_Result, // from tx initiated after done test
    input               i_logged_val_result,                        // i_VAL_Result_logged from comparator after detection val pattern
    input   [15:0]      i_logged_lane_id_result,                    // i_REVERSAL_Result_logged from comparator after detection reversal pattern
    ////////////////////////////////////
    //////////MB or reversal module not implemented yet 
    //////////////////////////////////
    input          i_valid_framing_error,             ///coming from MAINBAND
    input          i_REVERSAL_done,                   // (not sure )from the block which prepare the reversal 
    input          i_CLK_Track_done,
    input          i_LaneID_Pattern_done,             //from REVERSALMB_Wrapper
    input   [2:0]  i_logged_clk_result,               // i_Clock_track_result_logged from comparator after detection clk pattern
    //////////////////////
    /////patern generator 
    ///////////////////
    input          i_VAL_Pattern_done,

    //////////////////////
    /////output for reversal MB module 
    ///////////////////
    output  [1:0]       o_MBINIT_REVERSALMB_LaneID_Pattern_En,  // send to the REVERSALMB to send lane id pattern
    output              o_MBINIT_REVERSALMB_ApplyReversal_En,  // send to the REVERSALMB to apply reversal pattern
    output   [1:0]   o_Clear_Pattern_Comparator, // clear the comparator  
    output   [1:0]   o_Functional_Lanes_out_tx,    // not sure where to go 
    output   [1:0]   o_Functional_Lanes_out_rx,    // not sure where to go  (mapper / demapper)
    ////3ala mas2olit hazeeeeeeemmm ashrafff 
    output              o_Final_ClockMode,
    output              o_Final_ClockPhase,
    output              o_enable_cons,
    output              o_clear_clk_detection,  // for clk_detection to clear its result for detect another one

    ////////////////////////////////////
    ////output for clk pattern generator 
    ////////////////////////////////////
    output              o_MBINIT_REPAIRCLK_Pattern_En, // send to the CLK_PATTERN_GENERATOR to send clk pattern
    output              o_MBINIT_REPAIRVAL_Pattern_En, // send to the VAL_PATTERN_GENERATOR to send val pattern   
    output              o_Transmitter_initiated_Data_to_CLK_en,
    output              o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK,  // send to the point test
    output              o_mainband_Transmitter_initiated_Data_to_CLK, // send to the point test
    
    
    output        o_timeout_disable,   
    //analog component control word 
    output   [3:0] o_reciever_ref_voltage ,
    output  [3:0] o_pi_step,  
    /////////////////////
    //////poit test or pattern generator 
    /////////////////////////////////////
    output        o_tx_mainband_or_valtrain_test ,
    output        o_rx_mainband_or_valtrain_test ,
    output        o_rx_pt_en ,
    output        o_tx_eye_width_sweep_en ,
    
    output [2:0]  o_curret_operating_speed ,
    /////////RDI output 
    output     o_pl_trainerror   

);
/////////// out from ltsm to sideband 
wire w_is_tx_data_valid,w_is_msg_valid ;
wire [3:0]  w_is_sub_state, w_is_msg_no , w_state;// (w_state) de m4 output from ltsm
wire [2:0]  w_is_msg_info ;
wire [15:0] w_is_data_bus ;
wire        w_start_pattern_req ;
////////// out from sideband to ltsm  
wire         w_os_msg_valid ;
wire  [3:0]  w_os_msg_no ; 
wire  [2:0]  w_os_msg_info ;
wire  [15:0] w_os_data ;
wire w_os_sb_busy , w_sb_pattern_detect_done_rx , w_sb_pattern_detect_done_rx_fast ;
wire  o_clk_div8;


LTSM_wrapper ltsm_dut(
    
.i_clk(o_clk_div8),
.i_rst_n(i_rst_n),
.i_lp_linkerror(i_lp_linkerror),
.i_start_training_rdi(i_start_training_rdi),
.i_go_to_phyretrain_ACTIVE(i_go_to_phyretrain_ACTIVE),
.i_reciever_ref_voltage(i_reciever_ref_voltage),
.i_tx_point_test_ack(i_tx_point_test_ack),
.i_rx_point_test_ack(i_rx_point_test_ack),

.i_tx_lanes_result(i_tx_lanes_result),

.i_rx_lanes_result(i_rx_lanes_result),
.i_selfcal_done_ack(i_selfcal_done_ack),
.i_rx_cal_done_ack(i_rx_cal_done_ack),
.i_reset_resolved_state(i_reset_resolved_state),
.i_time_out(i_time_out),
.i_decoded_SB_msg(w_os_msg_no),
.i_sb_busy(w_os_sb_busy),
.i_rx_msg_valid(w_os_msg_valid_slow),
.i_rx_msg_info(w_os_msg_info),
.i_rx_data_bus(w_os_data),
.i_start_receiving_pattern(i_start_receiving_pattern),
.i_start_pattern_done(w_sb_pattern_detect_done_rx_fast),
.i_ACTIVE_DONE(i_ACTIVE_DONE),
.i_LINKINIT_DONE(i_LINKINIT_DONE),

.i_Transmitter_initiated_Data_to_CLK_done(i_Transmitter_initiated_Data_to_CLK_done),   // from tx initiated after done test
.i_Transmitter_initiated_Data_to_CLK_Result(i_Transmitter_initiated_Data_to_CLK_Result), // from tx initiated after done test
.i_logged_val_result(i_logged_val_result),                        // i_VAL_Result_logged from comparator after detection val pattern
.i_logged_lane_id_result(i_logged_lane_id_result),                    // i_REVERSAL_Result_logged from comparator after detection reversal pattern
////////////////////////////////////
//////////MB or reversal module not implemented yet 
//////////////////////////////////
.i_valid_framing_error(i_valid_framing_error),             ///coming from MAINBAND
.i_REVERSAL_done(i_REVERSAL_done),                   // (not sure )from the block which prepare the reversal 
.i_CLK_Track_done(i_CLK_Track_done),
.i_LaneID_Pattern_done(i_LaneID_Pattern_done),             //from REVERSALMB_Wrapper
.i_logged_clk_result(i_logged_clk_result),               // i_Clock_track_result_logged from comparator after detection clk pattern
//////////////////////
/////patern generator 
///////////////////
.i_VAL_Pattern_done(i_VAL_Pattern_done),

///////////////////
///output 
//////////////////


.o_encoded_SB_msg(w_is_msg_no),
.o_tx_msg_valid(w_is_msg_valid),
.o_state(w_state ),
.o_tx_sub_state(w_is_sub_state),
.o_tx_data_bus(w_is_data_bus),
.o_tx_msg_info(w_is_msg_info),
.o_tx_data_valid(w_is_tx_data_valid),
.o_start_pattern_req(w_start_pattern_req),

.o_MBINIT_REVERSALMB_LaneID_Pattern_En(o_MBINIT_REVERSALMB_LaneID_Pattern_En),
.o_MBINIT_REVERSALMB_ApplyReversal_En(o_MBINIT_REVERSALMB_ApplyReversal_En),
.o_Clear_Pattern_Comparator(o_Clear_Pattern_Comparator),
.o_Functional_Lanes_out_tx(o_Functional_Lanes_out_tx),
.o_Functional_Lanes_out_rx(o_Functional_Lanes_out_rx),

.o_Final_ClockMode(o_Final_ClockMode),
.o_Final_ClockPhase(o_Final_ClockPhase),
.o_enable_cons(o_enable_cons),
.o_clear_clk_detection(o_clear_clk_detection),

.o_MBINIT_REPAIRCLK_Pattern_En(o_MBINIT_REPAIRCLK_Pattern_En),
.o_MBINIT_REPAIRVAL_Pattern_En(o_MBINIT_REPAIRVAL_Pattern_En),
.o_Transmitter_initiated_Data_to_CLK_en(o_Transmitter_initiated_Data_to_CLK_en),

.o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK(o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK),
.o_mainband_Transmitter_initiated_Data_to_CLK(o_mainband_Transmitter_initiated_Data_to_CLK),
.o_timeout_disable(o_timeout_disable),
.o_reciever_ref_voltage(o_reciever_ref_voltage),
.o_pi_step(o_pi_step),
.o_tx_mainband_or_valtrain_test(o_tx_mainband_or_valtrain_test),


.o_rx_mainband_or_valtrain_test(o_rx_mainband_or_valtrain_test),
.o_rx_pt_en(o_rx_pt_en),
.o_tx_eye_width_sweep_en(o_tx_eye_width_sweep_en),
.o_curret_operating_speed(o_curret_operating_speed),
.o_pl_trainerror(o_pl_trainerror)

);

sb_wrapper sb_dut(
.i_clk(i_clk),
.i_rst_n(i_rst_n),
// input from ltsm
.i_data_valid(w_is_tx_data_valid),// input data valid from ltsm
.i_msg_valid(w_is_msg_valid),     // input msg valid from ltsm
.i_state(w_state),
.i_sub_state(w_is_sub_state),
.i_msg_no(w_is_msg_no),
.i_msg_info(w_is_msg_info),
.i_data_bus(w_is_data_bus),
.i_start_pattern_req(w_start_pattern_req),
// input from point test 
.i_tx_point_sweep_test_en(i_tx_point_sweep_test_en),
.i_tx_point_sweep_test(i_tx_point_sweep_test),
.i_pattern_detected(i_pattern_detected),
// input the other die 
.RXCKSB(RXCKSB), // come from testbench 
.RXDATASB(RXDATASB), // come from testbench 

// outputs for the other partener
.TXDATASB(TXDATASB),
.TXCKSB(TXCKSB),
//output for the ltsm
.o_sb_busy(w_os_sb_busy),
.o_pattern_time_out(o_pattern_time_out),
.o_tx_point_sweep_test_en(o_tx_point_sweep_test_en),
.o_tx_point_sweep_test(o_tx_point_sweep_test),
.o_msg_valid(w_os_msg_valid),
.o_msg_no(w_os_msg_no),
.o_msg_info(w_os_msg_info),
.o_data(w_os_data),
.o_sb_pattern_detect_done_rx(w_sb_pattern_detect_done_rx)
);
pulse_synchronizer pattern_detect_dut(
    .i_slow_clock(o_clk_div8),
    .i_fast_clock(i_clk),
    .i_rst_n(i_rst_n),
    .i_fast_pulse(w_sb_pattern_detect_done_rx),
    .o_slow_pulse(w_sb_pattern_detect_done_rx_fast)
);

pulse_synchronizer msg_valid_dut(
    .i_slow_clock(o_clk_div8),
    .i_fast_clock(i_clk),
    .i_rst_n(i_rst_n),
    .i_fast_pulse(w_os_msg_valid),
    .o_slow_pulse(w_os_msg_valid_slow)
);


clk_div8 clk_dut(
    .i_clk(i_clk),     // input clock
    .i_rst_n(i_rst_n),   // active-low reset
    .o_clk_div8(o_clk_div8) // divided clock (clk/8)
);



endmodule 