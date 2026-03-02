module mbtrain_wrapper (
    //inputs 
        //main control signals 
            input        clk,    // Clock
            input        i_en, // Clock Enable
            input        rst_n,  // Asynchronous reset active low
        //communicating with sideband 
            input [3:0]  i_sideband_message ,
            input [15:0] i_sideband_data , 
            input        i_busy,
            input        i_falling_edge_busy,
            input        i_sideband_valid,
            input [2:0]  i_sideband_data_lanes_encoding ,
        //talking with point test block 
            input        i_tx_point_test_ack  , i_rx_point_test_ack  ,
            input [15:0] i_tx_lanes_result    , i_rx_lanes_result,
        //still doesn't have a source 
            input        i_valid_framing_error,
        // communicating with ltsm (new)
            input [1:0]  i_phyretrain_resolved_state,
        //inputs from mbinit (new)
            input [2:0] i_highest_common_speed,
            input       i_first_8_tx_lanes_are_functional_mbinit , i_second_8_tx_lanes_are_functional_mbinit,
            input       i_first_8_rx_lanes_are_functional_mbinit , i_second_8_rx_lanes_are_functional_mbinit,
            input [3:0] i_reciever_ref_voltage ,

    //output
        //communicating with sideband 
            output  [3:0] o_sideband_substate,
            output  [3:0] o_sideband_message ,
            output  [2:0] o_sideband_data_lanes_encoding ,
            output        o_timeout_disable, o_valid ,
        //analog component control word 
            output  [3:0] o_reciever_ref_voltage ,o_pi_step,
        //communicating with point test 
            output        o_tx_mainband_or_valtrain_test , o_tx_lfsr_or_perlane,
            output        o_rx_mainband_or_valtrain_test ,
            output        o_tx_pt_en , o_rx_pt_en ,
            output        o_tx_eye_width_sweep_en , o_rx_eye_width_sweep_en ,
        //comunicating with phy retrain 
            output [1:0] o_phyretrain_error_encoding,
        // finishing ack
            output        o_mbtrain_ack,
        //communicating with pattern generators and detectors (new) 
            output        o_first_8_tx_lanes_are_functional , o_second_8_tx_lanes_are_functional,
            output        o_first_8_rx_lanes_are_functional , o_second_8_rx_lanes_are_functional ,
        //phy_retrain_enable (new)
            output        o_phyretrain_en ,
        //communicating with pll
            output  [2:0] o_curret_operating_speed 
);

 /*------------------------------------------------------------------------------
 --selfcal signals  
 ------------------------------------------------------------------------------*/
    //inputs 
    wire i_en_selfcal;
    //outputs
    wire  [3:0] o_sideband_message_selfcal ;
    wire        o_valid_selfcal;
    wire        o_test_ack_selfcal;

 /*------------------------------------------------------------------------------
 --vref_cal signals  (UPDATED)
 ------------------------------------------------------------------------------*/
    //inputs 
    wire        i_en_vref_cal;
    wire [1:0]  i_vref_mode; // NEW

    //outputs
    wire  [3:0] o_sideband_message_vref_cal ;
    wire        o_valid_vref_cal;
    wire        o_pt_en_vref_cal;

    // NEW: split acks
    wire        o_valvref_ack_vref_cal;
    wire        o_datavref_ack_vref_cal;
    wire        o_valtrainvref_ack_vref_cal;
    wire        o_datatrainvref_ack_vref_cal;

    // optional status/debug
    wire        o_vref_fail_vref_cal;
    wire [15:0] o_vref_lane_mask_vref_cal;

 /*------------------------------------------------------------------------------
 --train center cal  signals  (UPDATED)
 ------------------------------------------------------------------------------*/
    //inputs 
    wire        i_en_train_center_cal;
    wire [1:0]  i_train_center_mode; // NEW

    //outputs
    wire  [3:0] o_sideband_message_train_center_cal ;
    wire        o_valid_train_center_cal;
    wire        o_pt_en_train_center_cal;
    wire        o_tx_mainband_or_valtrain_test_train_center_cal;

    // NEW: split acks
    wire        o_val_train_center_ack_train_center_cal;
    wire        o_data_train_center_1_ack_train_center_cal;
    wire        o_data_train_center_2_ack_train_center_cal;

 /*------------------------------------------------------------------------------
 --RX cal  signals  
 ------------------------------------------------------------------------------*/
    //inputs 
    wire i_en_rx_cal;
    //outputs
    wire  [3:0] o_sideband_message_rx_cal ;
    wire        o_valid_rx_cal;
    wire        o_test_ack_rx_cal;
    wire        i_test_ack ;

 /*------------------------------------------------------------------------------
 --repair signals  
 ------------------------------------------------------------------------------*/
    //outputs
    wire  [3:0] o_sideband_message_repair ;
    wire        o_valid_repair;
    wire        o_test_ack_repair;
    wire        o_remote_partner_first_8_lanes_result_repair , o_remote_partner_second_8_lanes_result_repair;

 /*------------------------------------------------------------------------------
 --linksped signals  
 ------------------------------------------------------------------------------*/
    wire        i_en_linkspeed;
    wire  [3:0] o_sideband_message_linkspeed ;
    wire        o_valid_linkspeed;
    wire        o_test_ack_linkspeed;

    //next state flags
    wire o_phy_retrain_req_was_sent_or_received, o_error_req_was_sent_or_received;
    wire o_speed_degrade_req_was_sent_or_received, o_repair_req_was_sent_or_received;

    //talking with mbtrain controller
    wire o_local_first_8_lanes_are_functional_linkspeed ,o_local_second_8_lanes_are_functional_linkspeed;

    //point test control signals
    wire o_pt_en_linkspeed;
    wire o_tx_mainband_or_valtrain_test_linkspeed;

 /*------------------------------------------------------------------------------
 --mbtrain controller signals   
 ------------------------------------------------------------------------------*/
    //outputs from controller (enables)
    wire   o_valvref_en, o_data_vref_en, o_speed_idle_en, o_tx_self_cal_en;
    wire   o_rx_clk_cal_en, o_val_train_center_en, o_val_train_vref_en, o_data_train_center_1_en;
    wire   o_data_train_vref_en, o_rx_deskew_en, o_data_train_center_2_en, o_link_speed_en, o_repair_en;

    //mux select
    wire [2:0] o_mux_sel;

    // communicating with linkspeed
    wire o_comming_from_repair;

    // deciding which test (from controller)
    wire o_mainband_or_valtrain_test_controller;


 /*------------------------------------------------------------------------------
 --assign statements   
 ------------------------------------------------------------------------------*/
    //point test enables 

    assign i_test_ack   = i_tx_point_test_ack ;
    assign o_rx_pt_en   = o_pt_en_vref_cal;
    assign o_tx_pt_en   = o_pt_en_linkspeed || o_pt_en_train_center_cal;

    assign o_tx_mainband_or_valtrain_test =
        o_tx_mainband_or_valtrain_test_linkspeed || o_tx_mainband_or_valtrain_test_train_center_cal;

    // NOTE: new vref wrapper doesn't expose eye sweep yet => keep low for now
    assign o_rx_eye_width_sweep_en = 1'b0;

    // self cal enable 
    assign i_en_selfcal = o_speed_idle_en || o_tx_self_cal_en;

    // vref cal enable (same as before)
    assign i_en_vref_cal =
        o_val_train_vref_en   || o_data_train_vref_en  ||
        o_valvref_en          || o_data_vref_en;

    // NEW: derive vref_mode from controller enables (one-hot expected)
    assign i_vref_mode =
        (o_valvref_en)         ? 2'd0 :
        (o_data_vref_en)       ? 2'd1 :
        (o_val_train_vref_en)  ? 2'd2 :
        (o_data_train_vref_en) ? 2'd3 :
                                 2'd0;

    // train center enable 
    assign i_en_train_center_cal = o_val_train_center_en || o_data_train_center_1_en || o_data_train_center_2_en;

    // NEW: derive train_center_mode from controller enables
    assign i_train_center_mode =
        (o_val_train_center_en)     ? 2'd0 :
        (o_data_train_center_1_en)  ? 2'd1 :
        (o_data_train_center_2_en)  ? 2'd2 :
                                      2'd0;

    // rx cal enable 
    assign i_en_rx_cal = o_rx_deskew_en  || o_rx_clk_cal_en;

    // valid OR
    assign o_valid =
        o_valid_repair          || o_valid_selfcal          || o_valid_linkspeed ||
        o_valid_vref_cal        || o_valid_train_center_cal || o_valid_rx_cal;

 
 selfcal_wrapper selfcal_wrapper_inst(
    //inputs
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en_selfcal),
        .i_decoded_sideband_message(i_sideband_message),
        .i_busy_negedge_detected(i_falling_edge_busy),


        .i_sideband_valid(i_sideband_valid),
    //outputs
        .o_sideband_message(o_sideband_message_selfcal),
        .o_valid(o_valid_selfcal),
        .o_test_en(o_test_en),//
        .o_self_cal_ack(o_test_ack_selfcal)
);

 /*------------------------------------------------------------------------------
 --vrefcal wrapper (UPDATED)
 ------------------------------------------------------------------------------*/

   
vref_cal_wrapper vref_cal_wrapper_inst(
    //inputs
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en_vref_cal),

        .i_test_ack(i_test_ack),//

        .i_decoded_sideband_message(i_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_falling_edge_busy),

        .i_algo_done_ack(i_tx_point_test_ack),
        .i_rx_lanes_result(i_rx_lanes_result),

        .i_mainband_or_valtrain_test(o_mainband_or_valtrain_test_controller),
        .i_reciever_ref_voltage(i_reciever_ref_voltage),

    //outputs
        .o_sideband_message(o_sideband_message_vref_cal),
        .o_valid(o_valid_vref_cal),

        .o_pt_en(o_pt_en_vref_cal),
        .o_mainband_or_valtrain_test(o_rx_mainband_or_valtrain_test),

        .o_valvref_done(o_valvref_done),
        

        .o_valvref_fail(o_vref_fail_vref_cal),
        .o_valvref_lane_mask(o_vref_lane_mask_vref_cal),

        .o_reciever_ref_voltage(o_reciever_ref_voltage)
);

 /*------------------------------------------------------------------------------
 --train center cal  (UPDATED: new wrapper with i_mode + split ACKs)
 ------------------------------------------------------------------------------*/
train_center_cal_wrapper train_center_cal_wrapper_inst(
    //inputs
 
    // 0: VALTRAINCENTER, 1: DATATRAINCENTER1, 2: DATATRAINCENTER2

    // sideband decoded RX
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en_train_center_cal),
        .i_decoded_sideband_message(i_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_falling_edge_busy),

        .i_mainband_or_valtrain_test(o_mainband_or_valtrain_test_controller),
        .i_lfsr_or_perlane(1'b0),                 // TODO: hook real source if you have one

        .i_algo_done_ack(i_tx_point_test_ack),
        .i_tx_lanes_result(i_tx_lanes_result),

    //outputs
        .o_sideband_message(o_sideband_message_train_center_cal),
        .o_valid(o_valid_train_center_cal),

        .o_pt_en(o_pt_en_train_center_cal),

        .o_mainband_or_valtrain_test(o_tx_mainband_or_valtrain_test_train_center_cal),

        .o_pi_step(o_pi_step),

        .o_traincenter_ack(o_traincenter_ack),//
        .o_center_fail(o_center_fail),//
        .o_center_lane_mask(o_center_lane_mask)//
);

 /*------------------------------------------------------------------------------
 --rx cal   
 ------------------------------------------------------------------------------*/
rx_cal_wrapper rx_cal_wrapper_inst(
    //inputs

        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en_rx_cal),
        .i_rx_cal_done_ack(i_rx_cal_done_ack),
        .i_decoded_sideband_message(i_sideband_message),
        .i_busy_negedge_detected(i_falling_edge_busy),
        .i_sideband_valid(i_sideband_valid),
    //outputs
        .o_sideband_message(o_sideband_message_rx_cal),
        .o_valid(o_valid_rx_cal),
        .o_rx_cal_ack(o_test_ack_rx_cal)//
);

 /*------------------------------------------------------------------------------
 --repair wrapper  
 ------------------------------------------------------------------------------*/
repair_wrapper repair_wrapper_inst(
    //inputs 
        .clk(clk),
        .rst_n(rst_n),
        .i_en(o_repair_en),
        .i_sideband_message(i_sideband_message),
        .i_sideband_valid(i_sideband_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_sideband_data_lanes_encoding(i_sideband_data_lanes_encoding),
        .i_first_8_lanes_are_functional(o_local_first_8_lanes_are_functional_linkspeed),
        .i_second_8_lanes_are_functional(o_local_first_8_lanes_are_functional_linkspeed),
    //outputs
        .o_valid(o_valid_repair),
        .o_sideband_data_lanes_encoding(o_sideband_data_lanes_encoding),
        .o_sideband_message(o_sideband_message_repair),
        .o_remote_partner_first_8_lanes_result(o_remote_partner_first_8_lanes_result_repair),
        .o_remote_partner_second_8_lanes_result(o_remote_partner_second_8_lanes_result_repair),
        .o_test_ack(o_test_ack_repair)
);

 /*------------------------------------------------------------------------------
 --linkspeed wrapper   
 ------------------------------------------------------------------------------*/
linkspeed_wrapper linkspeed_wrapper_inst(
    //inputs
        .clk(clk),
        .rst_n(rst_n),
        .i_en(o_link_speed_en),
        .i_sideband_message(i_sideband_message),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_sideband_valid(i_sideband_valid),
        .i_point_test_ack(i_tx_point_test_ack),
        .i_lanes_result(i_tx_lanes_result),
        .i_valid_framing_error(i_valid_framing_error),
        .i_first_8_tx_lanes_are_functional(o_first_8_tx_lanes_are_functional),
        .i_second_8_tx_lanes_are_functional(o_second_8_tx_lanes_are_functional),
        .i_comming_from_repair(o_comming_from_repair),
    //outputs
        .o_valid(o_valid_linkspeed),
        .o_sideband_message(o_sideband_message_linkspeed),
        .o_link_speeed_ack(o_test_ack_linkspeed),
        .o_phy_retrain_req_was_sent_or_received(o_phy_retrain_req_was_sent_or_received),
        .o_error_req_was_sent_or_received(o_error_req_was_sent_or_received),
        .o_speed_degrade_req_was_sent_or_received(o_speed_degrade_req_was_sent_or_received),
        .o_repair_req_was_sent_or_received(o_repair_req_was_sent_or_received),
        .o_phyretrain_error_encoding(o_phyretrain_error_encoding),
        .o_local_first_8_lanes_are_functional(o_local_first_8_lanes_are_functional_linkspeed),
        .o_local_second_8_lanes_are_functional(o_local_second_8_lanes_are_functional_linkspeed),
        .o_point_test_en(o_pt_en_linkspeed)
);

 /*------------------------------------------------------------------------------
 -- mbtrain controller  (UPDATED ACK WIRING for VREF + TRAIN_CENTER)
 ------------------------------------------------------------------------------*/
mbtrain_controller mbtrain_controller_inst(

        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_phyretrain_resolved_state(i_phyretrain_resolved_state),

        .i_highest_common_speed(i_highest_common_speed),
        .i_first_8_tx_lanes_are_functional_mbinit(i_first_8_tx_lanes_are_functional_mbinit),
        .i_second_8_tx_lanes_are_functional_mbinit(i_second_8_tx_lanes_are_functional_mbinit),
        .i_first_8_rx_lanes_are_functional_mbinit(i_first_8_rx_lanes_are_functional_mbinit),
        .i_second_8_rx_lanes_are_functional_mbinit(i_second_8_rx_lanes_are_functional_mbinit),

        .i_first_8_tx_lanes_are_functional_linkspeed(o_local_first_8_lanes_are_functional_linkspeed),
        .i_second_8_tx_lanes_are_functional_linkspeed(o_local_second_8_lanes_are_functional_linkspeed),
        .i_first_8_rx_lanes_are_functional_repair(o_remote_partner_first_8_lanes_result_repair),
        .i_second_8_rx_lanes_are_functional_repair(o_remote_partner_second_8_lanes_result_repair),

        .i_phy_retrain_req_was_sent_or_received(o_phy_retrain_req_was_sent_or_received),
        .i_error_req_was_sent_or_received(o_error_req_was_sent_or_received),
        .i_speed_degrade_req_was_sent_or_received(o_speed_degrade_req_was_sent_or_received),
        .i_repair_req_was_sent_or_received(o_repair_req_was_sent_or_received),

        // ACKs (UPDATED)
        .i_valvref_ack(o_valvref_ack_vref_cal),
        .i_data_vref_ack(o_datavref_ack_vref_cal),

        .i_speed_idle_ack(o_test_ack_selfcal),
        .i_tx_self_cal_ack(o_test_ack_selfcal),

        .i_rx_clk_cal_ack(o_test_ack_rx_cal),

        // TRAIN CENTER split ACKs
        .i_val_train_center_ack(o_val_train_center_ack_train_center_cal),
        .i_data_train_center_1_ack(o_data_train_center_1_ack_train_center_cal),
        .i_data_train_center_2_ack(o_data_train_center_2_ack_train_center_cal),

        // VREF train split ACKs
        .i_val_train_vref_ack(o_valtrainvref_ack_vref_cal),
        .i_data_train_vref_ack(o_datatrainvref_ack_vref_cal),

        .i_rx_deskew_ack(o_test_ack_rx_cal),
        .i_link_speed_ack(o_test_ack_linkspeed),
        .i_repair_ack(o_test_ack_repair),

    //outputs 
        .o_valvref_en(o_valvref_en),
        .o_data_vref_en(o_data_vref_en),

        .o_speed_idle_en(o_speed_idle_en),
        .o_tx_self_cal_en(o_tx_self_cal_en),

        .o_rx_clk_cal_en(o_rx_clk_cal_en),
        .o_val_train_center_en(o_val_train_center_en),

        .o_val_train_vref_en(o_val_train_vref_en),
        .o_data_train_center_1_en(o_data_train_center_1_en),

        .o_data_train_vref_en(o_data_train_vref_en),
        .o_rx_deskew_en(o_rx_deskew_en),

        .o_data_train_center_2_en(o_data_train_center_2_en),
        .o_link_speed_en(o_link_speed_en),

        .o_repair_en(o_repair_en),

        .o_mainband_or_valtrain_test(o_mainband_or_valtrain_test_controller),

        .o_phyretrain_en(o_phyretrain_en),

        .o_sideband_substate(o_sideband_substate),

        .o_first_8_tx_lanes_are_functional(o_first_8_tx_lanes_are_functional),
        .o_second_8_tx_lanes_are_functional(o_second_8_tx_lanes_are_functional),
        .o_first_8_rx_lanes_are_functional(o_first_8_rx_lanes_are_functional),
        .o_second_8_rx_lanes_are_functional(o_second_8_rx_lanes_are_functional),

        .o_mbtrain_ack(o_mbtrain_ack),

        .o_mux_sel(o_mux_sel),

        .o_comming_from_repair(o_comming_from_repair),

        .o_curret_operating_speed(o_curret_operating_speed)
);

 /*------------------------------------------------------------------------------
 --mux instantiations   
 ------------------------------------------------------------------------------*/
mux_6_to_1 mux_inst(
    .sel_0(o_mux_sel[0]), .sel_1(o_mux_sel[1]), .sel_2(o_mux_sel[2]),
    .in_1(o_sideband_message_vref_cal),
    .in_2(o_sideband_message_selfcal),
    .in_3(o_sideband_message_linkspeed),
    .in_4(o_sideband_message_repair),
    .in_5(o_sideband_message_train_center_cal),
    .in_6(o_sideband_message_rx_cal),
    .out(o_sideband_message)
);

endmodule
