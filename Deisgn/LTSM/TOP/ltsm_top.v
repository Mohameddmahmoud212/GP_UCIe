module LTSM_wrapper(
input           i_clk,
input           i_rst_n,
////////rdi interface
////////////////////////////
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
//////////////////////////////////////////////

////////////////////////////
///////sb
////////////////////////
//////////////////////////////////////////////
input           i_time_out,                 //time out for the sb pattern  (o_pattern_time_out)
input [3:0]     i_decoded_SB_msg,           // sb msg (o_msg_no)
input           i_sb_busy,          
input           i_rx_msg_valid,             //i_sideband_valid
input [2:0]     i_rx_msg_info,

input [15:0]    i_rx_data_bus,
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
/////output for sb 
///////////////////
output reg [3:0]   o_encoded_SB_msg,  // to SB (selected TX or RX)
output reg         o_tx_msg_valid  ,   // to SB (selected valid)
output reg [3:0]   o_state      ,
output reg [3:0]   o_tx_sub_state,
output     [15:0]  o_tx_data_bus,  // data field parameters (param) , 16 bits for results of the lanes (reversalmb)
output reg [2:0]   o_tx_msg_info,  // repair clk(results for clkn ,clkp,track) , repair val ,repair mb (functional lanes)
output             o_tx_data_valid,
output             o_start_pattern_req,//only for sb 
//////////////////////
/////output for reversal MB module 
///////////////////
output  [1:0]       o_MBINIT_REVERSALMB_LaneID_Pattern_En,  // send to the REVERSALMB to send lane id pattern
output              o_MBINIT_REVERSALMB_ApplyReversal_En,  // send to the REVERSALMB to apply reversal pattern
output      [1:0]   o_Clear_Pattern_Comparator, // clear the comparator  
output  reg [1:0]   o_Functional_Lanes_out_tx,    // not sure where to go 
output  reg [1:0]   o_Functional_Lanes_out_rx,    // not sure where to go  (mapper / demapper)
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
output reg             o_Transmitter_initiated_Data_to_CLK_en,
output reg          o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK,  // send to the point test
output              o_mainband_Transmitter_initiated_Data_to_CLK, // send to the point test
   
   
output        o_timeout_disable,   
//analog component control word 
output  reg [3:0] o_reciever_ref_voltage ,
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
output reg    o_pl_trainerror   
//////////
);

wire [3:0] sub_state_MBTRAIN ;
wire [1:0]  MBINIT_tx_Functional_Lanes_out  , MBINIT_rx_Functional_Lanes_out;
wire [1:0]  MBTRAIN_tx_Functional_Lanes_out , MBTRAIN_rx_Functional_Lanes_out;
wire [2:0]  w_Final_MaxDataRate ;
wire [1:0]  w_resolved_state ,w_phyretrain_error_encoding;
wire [3:0]  encoded_SB_msg_SBINIT , encoded_SB_msg_MBTRAIN ,encoded_SB_msg_MBINIT, encoded_SB_msg_PHYRETRAIN ,encoded_SB_msg_TRAINERROR;
wire [2:0]  msg_info_MBTRAIN, msg_info_MBINIT , msg_info_PHYRETRAIN;

wire        msg_valid_SBINIT ,msg_valid_MBTRAIN ,msg_valid_MBINIT ,msg_valid_PHYRETRAIN, msg_valid_TRAINERROR ;
reg         enter_from_active_or_mbtrain;
wire go_to_trainerror_MBINIT;
////////////////////////////////////////////
/////////////ENABLES Handling///////////////
////////////////////////////////////////////
reg     SBINIT_EN;
reg     MBINIT_EN;
reg     PHYRETRAIN_EN;
reg     MBTRAIN_EN;
reg     TRAINERROR_EN;


////////////////////////////////////////
/////////////END Handling///////////////
////////////////////////////////////////
wire     SBINIT_END;
wire     MBINIT_END;
wire     PHYRETRAIN_END;
wire     MBTRAIN_END;
wire     TRAINERROR_END;

wire go_to_phyretrain_MBTRAIN; //mtwsla bl en bt3 el mbtrain el leh 3laka bl phyretrain
wire trainerror_condition   = ( i_time_out || (i_decoded_SB_msg == 15 && i_rx_msg_valid) || i_lp_linkerror); 
// if (i_time_out) --> module iniates trainerror, if (i_decoded_SB_msg == 14) --> partner iniates trainerror, if bit [10] on DVSEC is set in any state rather than reset go to trainerror

localparam RESET        = 0;
localparam FINISH_RESET = 1;
localparam SBINIT       = 2;
localparam MBINIT       = 3;
localparam MBTRAIN      = 4;
localparam LINKINIT     = 5;
localparam ACTIVE       = 6;
localparam PHYRETRAIN   = 7;
localparam TRAINERROR_HS   = 8;


/////test


reg [18:0] reset_counter;           // lesa mumken el width ytghyyr  
reg [18:0] timeout_counter;         // lesa mumken el width ytghyyr  
localparam COUNT_4ms    = 4;        // should be changed depending on the operating frequncey
localparam COUNT_8ms    = 200000;   // should be changed depending on the operating frequncy
reg  start_reset_counter;           // htt3ml fl output logic awl m y7sl dectect ll pattern
wire counter_reset_flag     = (reset_counter == COUNT_4ms+1)? 1:0;
wire  MBTRAIN_Transmitter_initiated_Data_to_CLK_en , MBINIT_Transmitter_initiated_Data_to_CLK_en;
reg MBTRAIN_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK  ;
wire MBINIT_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK;//??? changed to wire
reg i_busy_reg;
wire w_falling_edg_busy ;
assign w_falling_edg_busy= ~i_sb_busy  && i_busy_reg; 
        
    mbtrain_wrapper MBTRAIN_dut(
        .clk(i_clk),   
        .i_en(MBTRAIN_EN), 
        .rst_n(i_rst_n),  
        .i_sideband_message(i_decoded_SB_msg),
        .i_falling_edge_busy(w_falling_edg_busy),
        .i_sideband_valid(i_rx_msg_valid),
        .i_sideband_data_lanes_encoding (i_rx_msg_info),
        .i_tx_point_test_ack  (i_tx_point_test_ack), 
        .i_rx_point_test_ack  (i_rx_point_test_ack),
        .i_tx_lanes_result    (i_tx_lanes_result), 
        .i_rx_lanes_result  (i_rx_lanes_result),
        .i_valid_framing_error(i_valid_framing_error),
        .i_phyretrain_resolved_state(w_resolved_state),
        .i_highest_common_speed(w_Final_MaxDataRate),
        .i_selfcal_done_ack(i_selfcal_done_ack),
        .i_rx_cal_done_ack(i_rx_cal_done_ack),
        .i_first_8_tx_lanes_are_functional_mbinit (MBINIT_tx_Functional_Lanes_out[0]), 
        .i_second_8_tx_lanes_are_functional_mbinit(MBINIT_tx_Functional_Lanes_out[1]),
        .i_first_8_rx_lanes_are_functional_mbinit (MBINIT_rx_Functional_Lanes_out[0]), 
        .i_second_8_rx_lanes_are_functional_mbinit(MBINIT_rx_Functional_Lanes_out[1]),
        .i_reciever_ref_voltage (i_reciever_ref_voltage),

        .o_sideband_substate(sub_state_MBTRAIN),
        .o_sideband_message(encoded_SB_msg_MBTRAIN),
        .o_sideband_data_lanes_encoding (msg_info_MBTRAIN),
        .o_timeout_disable(o_timeout_disable), 
        .o_valid (msg_valid_MBTRAIN),
        .o_reciever_ref_voltage (MBTRAIN_Vref),
        .o_pi_step(o_pi_step),
        .o_tx_mainband_or_valtrain_test (o_tx_mainband_or_valtrain_test), 
        
        .o_rx_mainband_or_valtrain_test (o_rx_mainband_or_valtrain_test),
        .o_tx_pt_en (MBTRAIN_Transmitter_initiated_Data_to_CLK_en), 
        .o_rx_pt_en (o_rx_pt_en),
        .o_tx_eye_width_sweep_en (o_tx_eye_width_sweep_en), 
        .o_phyretrain_error_encoding(w_phyretrain_error_encoding),
        .o_mbtrain_ack(MBTRAIN_END),   //DE EL END????? MBTRAIN_END
        .o_first_8_tx_lanes_are_functional (MBTRAIN_tx_Functional_Lanes_out[0]), 
        .o_second_8_tx_lanes_are_functional(MBTRAIN_tx_Functional_Lanes_out[1]),
        .o_first_8_rx_lanes_are_functional (MBTRAIN_rx_Functional_Lanes_out[0]), 
        .o_second_8_rx_lanes_are_functional (MBTRAIN_rx_Functional_Lanes_out[1]),
        .o_phyretrain_en (go_to_phyretrain_MBTRAIN),
        .o_curret_operating_speed (o_curret_operating_speed)
    );


    SBINIT_WRAPPER sbinit_wrapper_dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_SBINIT_en(SBINIT_EN),
        .i_start_pattern_done(i_start_pattern_done), 
        .i_rx_msg_valid(i_rx_msg_valid), 
        .i_sb_busy(i_sb_busy), 
        .i_decoded_SB_msg(i_decoded_SB_msg),
        
        .o_encoded_SB_msg(encoded_SB_msg_SBINIT),  
        .o_tx_msg_valid(msg_valid_SBINIT),  
        .o_start_pattern_req(o_start_pattern_req),
        .o_SBINIT_end(SBINIT_END) 
    );

    PHYRETRAIN_WRAPPER PHYRITRAIN_dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_PHYRETRAIN_en(PHYRETRAIN_EN),
        .i_enter_from_active_or_mbtrain(enter_from_active_or_mbtrain), 
        .i_link_status(w_phyretrain_error_encoding),     
        .i_reset_resolved_state(i_reset_resolved_state), 
        .i_sb_busy(i_sb_busy),          
        .i_rx_msg_valid(i_rx_msg_valid),    
        .i_decoded_SB_msg(i_decoded_SB_msg),
        .i_rx_msg_info(i_rx_msg_info),      
        .o_encoded_SB_msg(encoded_SB_msg_PHYRETRAIN), 
        .o_tx_msg_valid(msg_valid_PHYRETRAIN),   
        .o_tx_msg_info(msg_info_PHYRETRAIN),    
        .o_PHYRETRAIN_end(PHYRETRAIN_END), 
        .o_resolved_state(w_resolved_state)  
    );

    MBINIT MBINIT_dut(
        .CLK(i_clk),
        .rst_n(i_rst_n),
        .i_MBINIT_Start_en(MBINIT_EN),
        .i_rx_msg_no(i_decoded_SB_msg),
        .i_rx_data_bus(i_rx_data_bus),
        .i_rx_msg_info(i_rx_msg_info),
        .i_rx_busy(i_sb_busy),
        .i_falling_edge_busy(w_falling_edg_busy),
        .i_msg_valid(i_rx_msg_valid),
        .i_REVERSAL_done(i_REVERSAL_done),  // from the block which prepare the reversal 
        .i_CLK_Track_done(i_CLK_Track_done),
        .i_VAL_Pattern_done(i_VAL_Pattern_done),
        .i_LaneID_Pattern_done(i_LaneID_Pattern_done),    //from REVERSALMB_Wrapper
        .i_logged_clk_result(i_logged_clk_result),      // i_Clock_track_result_logged from comparator after detection clk pattern
        .i_logged_val_result(i_logged_val_result),      // i_VAL_Result_logged from comparator after detection val pattern
        .i_logged_lane_id_result(i_logged_lane_id_result),    // i_REVERSAL_Result_logged from comparator after detection reversal pattern
        .i_Transmitter_initiated_Data_to_CLK_done(i_Transmitter_initiated_Data_to_CLK_done),  // from tx initiated after done test
        .i_Transmitter_initiated_Data_to_CLK_Result(i_Transmitter_initiated_Data_to_CLK_Result),  // from tx initiated after done test

        .o_tx_sub_state(sub_state_MBINIT),
        .o_tx_msg_no(encoded_SB_msg_MBINIT),
        .o_tx_data_bus(o_tx_data_bus),  // data field parameters (param) , 16 bits for results of the lanes (reversalmb)
        .o_tx_msg_info(msg_info_MBINIT),  // repair clk(results for clkn ,clkp,track) , repair val ,repair mb (functional lanes)
        .o_tx_msg_valid(msg_valid_MBINIT),
        .o_tx_data_valid(o_tx_data_valid),
        .o_MBINIT_REPAIRCLK_Pattern_En(o_MBINIT_REPAIRCLK_Pattern_En), // send to the CLK_PATTERN_GENERATOR to send clk pattern
        .o_MBINIT_REPAIRVAL_Pattern_En(o_MBINIT_REPAIRVAL_Pattern_En),// send to the VAL_PATTERN_GENERATOR to send val pattern
        .o_MBINIT_REVERSALMB_LaneID_Pattern_En(o_MBINIT_REVERSALMB_LaneID_Pattern_En),  // send to the REVERSALMB to send lane id pattern
        .o_MBINIT_REVERSALMB_ApplyReversal_En(o_MBINIT_REVERSALMB_ApplyReversal_En), // send to the REVERSALMB to apply reversal pattern
        .o_Clear_Pattern_Comparator(o_Clear_Pattern_Comparator),// clear the comparator
        .o_Functional_Lanes_out_tx(MBINIT_tx_Functional_Lanes_out),
        .o_Functional_Lanes_out_rx(MBINIT_rx_Functional_Lanes_out),
        .o_Transmitter_initiated_Data_to_CLK_en(MBINIT_Transmitter_initiated_Data_to_CLK_en),
        .o_perlane_Transmitter_initiated_Data_to_CLK(MBINIT_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK),  // send to the point test
        .o_mainband_Transmitter_initiated_Data_to_CLK(o_mainband_Transmitter_initiated_Data_to_CLK), // send to the point test
        .o_Final_MaxDataRate(w_Final_MaxDataRate),  //For MBTRAIN 
        .o_Final_ClockMode(o_Final_ClockMode),
        .o_Final_ClockPhase(o_Final_ClockPhase),
        .o_train_error_req(go_to_trainerror_MBINIT),
        .o_enable_cons(o_enable_cons),
        .o_clear_clk_detection(o_clear_clk_detection), // for clk_detection to clear its result for detect another one
        .o_Finish_MBINIT(MBINIT_END)
    );

    TRAINERROR_HS_WRAPPER TRAINERROR_dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_trainerror_en(TRAINERROR_EN),
        .i_rx_msg_valid(i_rx_msg_valid),
        .i_decoded_SB_msg(i_decoded_SB_msg),

        .o_encoded_SB_msg(encoded_SB_msg_TRAINERROR),
        .o_TRAINERROR_HS_end(TRAINERROR_END),
        .o_tx_msg_valid(msg_valid_TRAINERROR)
    );

reg [2:0] CS , NS ; 
reg state_timeout ;
reg [3:0] reg_sub_state_MBINIT , reg_sub_state_MBTRAIN ;
wire reset_state_timeout_counter  = (CS == RESET || CS == FINISH_RESET || CS == ACTIVE 
                                     || CS == TRAINERROR_HS || CS != NS); 
// reset the counter if state is transitioning (CS!=NS) or if we are in the stated states dont count
/////////////////////////////////
///// RESET COUNTER (4 ms) //////
/////////////////////////////////
always @ (posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        reset_counter <= 0;
    end else if (counter_reset_flag) begin
        reset_counter <= 0;
    end else if (start_reset_counter) begin // this condition is used to prevent the counter from counting in other states to save power, just count when training is triggered
        reset_counter <= reset_counter + 1;
    end 
end
always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_timeout         <= 0;
        reg_sub_state_MBINIT  <= 0;
        reg_sub_state_MBTRAIN <= 0;        
    end else begin

        reg_sub_state_MBINIT  <= sub_state_MBINIT;
        reg_sub_state_MBTRAIN <= sub_state_MBTRAIN;
        state_timeout <= (timeout_counter == COUNT_8ms)? 1:0;
    end 
end

////////////////////////////////////////
//// STATE TIMEOUT COUNTER (8 ms) //////
////////////////////////////////////////
always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        timeout_counter <= 0;
    end else if (reset_state_timeout_counter) begin 
        timeout_counter <= 0;
    end else if (CS == MBINIT) begin
        if (reg_sub_state_MBINIT == sub_state_MBINIT) begin
            timeout_counter <= timeout_counter + 1;
        end else begin
            timeout_counter <= 0;
        end
    end else if (CS == MBTRAIN) begin
        if (reg_sub_state_MBTRAIN == sub_state_MBTRAIN) begin
            timeout_counter <= timeout_counter + 1;
        end else begin
            timeout_counter <= 0;
        end        
    end
    else if (CS == NS) begin
        timeout_counter <= timeout_counter + 1;
    end
end

/////////////////////////////////
//////// State Memory ///////////
/////////////////////////////////
always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        CS <= RESET;   //*********mhtagen n3mlha fl SB******* BDL EL i_rst_n
    end
    else begin
        CS <= NS;
    end
end

///////////////////////////////////////
/////////////////NS LOGIC//////////////
///////////////////////////////////////

always @ (*) begin
   
    case (CS) 
        //RESET
        RESET: begin
            if (i_start_receiving_pattern || i_start_training_rdi) begin // req from the other die or from rdi 
                NS = FINISH_RESET;
            end else begin
                NS = RESET;
            end
        end
        //FINISH_RESET
        FINISH_RESET: begin
            if (reset_counter == COUNT_4ms) begin
                NS = SBINIT;
            end else begin
                NS = FINISH_RESET;
            end
        end
        //SBINIT
        SBINIT: begin
            
            if (trainerror_condition) begin    //not done yet
                NS = TRAINERROR_HS;
            end else begin
                if (SBINIT_END) begin
                    NS = MBINIT;
                end else begin
                    NS = SBINIT;
                end   
            end   
        end 
        // MBINIT
        MBINIT: begin
            
            if (go_to_trainerror_MBINIT || trainerror_condition) begin   //not done yet
                NS = TRAINERROR_HS;
            end else begin
                if (MBINIT_END) begin
                    NS = MBTRAIN;
                end else begin
                    NS = MBINIT;
                end
            end            
        end
// MBTRAIN

        MBTRAIN: begin
        
            if (trainerror_condition) begin //not done yet
                NS = TRAINERROR_HS;
            end else begin
                if (go_to_phyretrain_MBTRAIN) begin
                    NS = PHYRETRAIN;
                end else if (MBTRAIN_END) begin
                    NS = LINKINIT;
                end else begin
                    NS = MBTRAIN;
                end
            end            
        end
    LINKINIT: begin
                if (trainerror_condition) begin 
                    NS = TRAINERROR_HS;
                end else if (i_LINKINIT_DONE) begin ///////// lesa msh 3arf el condition dh is set based 3ala eh bas ghalbn related bl RDI ????????? ////////////////
                    NS = ACTIVE;
                end else begin
                    NS = LINKINIT;
                end           
            end
    /*-----------------------------------------------------------------------------
    * ACTIVE
    *-----------------------------------------------------------------------------*/
    ACTIVE: begin
        if (trainerror_condition) begin
            NS = TRAINERROR_HS;
        end else if (i_valid_framing_error || i_go_to_phyretrain_ACTIVE || i_decoded_SB_msg == 1) begin // (i_valid_framing_error) --> PHY iniated PHYRETRAIN ,(i_go_to_phyretrain_ACTIVE) --> Adapter iniated PHYRETRAIN
            NS = PHYRETRAIN; // should be LINKMGMT_RETRAIN                                     // (i_decoded_SB_msg == 1) --> linkmgmt.RDI.Retrain.Req .. Remote partner iniated retrain
        end else if (i_ACTIVE_DONE) begin ///////// lesa msh 3arf el condition dh is set based 3ala eh bas ghalbn related bl RDI ????????? ////////////////
            NS = RESET;
        end else begin
            NS = ACTIVE;
        end
    end


// TRAINERROR MSH MOT2KD KHALS

        TRAINERROR_HS: begin
            
            if (TRAINERROR_END) begin   //trainerror_END btkon wahed emta??
                NS = RESET;
            end else begin
                NS = TRAINERROR_HS;
            end   
        end


//PHYRETRAIN
        PHYRETRAIN: begin
            
            if (trainerror_condition) begin  //not done yet
                NS = TRAINERROR_HS;
            end else begin
                if (PHYRETRAIN_END) begin
                    NS = MBTRAIN;
                end else begin
                    NS = PHYRETRAIN;
                end
            end            
        end
    endcase
end

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////OUTPUT LOGIC/////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

always @(posedge i_clk or negedge i_rst_n) begin //used for the falling edg busy 
    if(~i_rst_n) begin
        i_busy_reg <= 0;
    end else begin
        i_busy_reg <= i_sb_busy;
    end
end
/*---------------------------------------
* tx iniated D2C point test signals
---------------------------------------*/
always @ (*) begin
    case (CS)
        MBINIT: begin
            //o_mainband_or_valtrain_Transmitter_initiated_Data_to_CLK = MBINIT_mainband_or_valtrain_Transmitter_initiated_Data_to_CLK;
            o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK      = MBINIT_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK;
            o_Transmitter_initiated_Data_to_CLK_en                   = MBINIT_Transmitter_initiated_Data_to_CLK_en;
        end
        MBTRAIN: begin
            //o_mainband_or_valtrain_Transmitter_initiated_Data_to_CLK = MBTRAIN_mainband_or_valtrain_Transmitter_initiated_Data_to_CLK;
            o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK      = MBTRAIN_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK;
            o_Transmitter_initiated_Data_to_CLK_en                   = MBTRAIN_Transmitter_initiated_Data_to_CLK_en;
        end
        default: begin
            //o_mainband_or_valtrain_Transmitter_initiated_Data_to_CLK = 0;
            o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK      = 0;
            o_Transmitter_initiated_Data_to_CLK_en                   = 0;          
        end
    endcase
end



always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        start_reset_counter <= 0;
        enter_from_active_or_mbtrain <= 0;
        SBINIT_EN       <= 0;
        MBINIT_EN       <= 0;
        MBTRAIN_EN      <= 0;
        TRAINERROR_EN   <= 0;
        PHYRETRAIN_EN   <= 0;
    end else begin
        //defaults
        SBINIT_EN       <= 0;
        MBINIT_EN       <= 0;
        MBTRAIN_EN      <= 0;
        TRAINERROR_EN   <= 0;
        PHYRETRAIN_EN   <= 0;
        case (CS)
        /*-----------------------------------------------------------------------------
        * SBINIT
        *-----------------------------------------------------------------------------*/
            SBINIT: begin
                o_state   <= 0;//added
                SBINIT_EN <= 1;
            end 
        /*-----------------------------------------------------------------------------
        * MBINIT
        *-----------------------------------------------------------------------------*/
            MBINIT: begin
                o_state   <= 1;
                MBINIT_EN <= 1;
            end
        /*-----------------------------------------------------------------------------
        * MBTRAIN
        *-----------------------------------------------------------------------------*/
            MBTRAIN: begin
                o_state    <= 2;
                MBTRAIN_EN <= 1;      
            end

        /*-----------------------------------------------------------------------------
        * TRAINERROR
        *-----------------------------------------------------------------------------*/
            TRAINERROR_HS: begin
                 o_state   <= 4;
                TRAINERROR_EN <= 1;
                
            end
        /*-----------------------------------------------------------------------------
        * PHYRETRAIN
        *-----------------------------------------------------------------------------*/
            PHYRETRAIN: begin
                 o_state   <= 3;
                PHYRETRAIN_EN <= 1;         
            end
        /*-----------------------------------------------------------------------------
        * DEFAULT
        *-----------------------------------------------------------------------------*/        
            default: begin
                SBINIT_EN       <= 0;
                MBINIT_EN       <= 0;
                MBTRAIN_EN      <= 0;
                TRAINERROR_EN   <= 0;
                PHYRETRAIN_EN   <= 0;
                o_pl_trainerror <= 0;
            end
        endcase
        /*-----------------------------------------------------------------------
        * Reset counter related logic
        -----------------------------------------------------------------------*/
        if (i_start_receiving_pattern || i_start_training_rdi)/// i_start_training_rdi added 
            start_reset_counter <= 1;
        else if (reset_counter == COUNT_4ms+1) 
            start_reset_counter <= 0;
        /*-----------------------------------------------------------------------
        * PHYRETRAIN related logic  ehna m3ndnash active state??!!
        -----------------------------------------------------------------------*/
        if (go_to_phyretrain_MBTRAIN) begin  
            enter_from_active_or_mbtrain <= 1; // PHYRETRAIN entered from MBTRAIN.LINKSPEED
        end else if (CS == ACTIVE && NS == PHYRETRAIN) begin 
            enter_from_active_or_mbtrain <= 0; // PHYRETRAIN entered from ACTIVE
        end
        //clear_resolved_state <= (NS == RESET)? 1:0; // because this resolved state goes to MBTRAIN block to go to either TXSELFCAL , SPEEDIDLE , REPAIR or start
        // from first state VALVREF as normal so, resolved state register should be cleared each time traning starts from the begining
    end
end 
///////////////////////////////////////////////////
/////////////////o_reciever_ref_voltage MUXING/////
///////////////////////////////////////////////////

always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_reciever_ref_voltage <= 0;
    end else begin
        if (CS == MBINIT) begin
        // o_reciever_ref_voltage <= MBINIT_Vref; // doesnot added in mbinit 
        end else if (CS == MBTRAIN) begin
            o_reciever_ref_voltage <= MBTRAIN_Vref;
        end
    end
end


///////////////////////////////////////////////////
/////////////////o_tx_msg_info MUXING/////
///////////////////////////////////////////////////
always @ (*) begin
    case (CS)
        MBINIT: begin
            o_tx_msg_info = msg_info_MBINIT;
        end
        MBTRAIN: begin
            o_tx_msg_info = msg_info_MBTRAIN;
        end
        PHYRETRAIN: begin
            o_tx_msg_info = msg_info_PHYRETRAIN;
        end
        default: o_tx_msg_info = 3'b000;
    endcase
end

///////////////////////////////////////////////////
/////////////////o_tx_msg_valid MUXING/////
///////////////////////////////////////////////////
always @ (*) begin
    case (CS)
        SBINIT: begin
            o_tx_msg_valid = msg_valid_SBINIT;
        end
        MBINIT: begin
            o_tx_msg_valid = msg_valid_MBINIT;
        end
        MBTRAIN: begin
            o_tx_msg_valid = msg_valid_MBTRAIN;
        end
        TRAINERROR_HS: begin
            o_tx_msg_valid = msg_valid_TRAINERROR;
        end
        PHYRETRAIN: begin
            o_tx_msg_valid = msg_valid_PHYRETRAIN;
        end
        default: o_tx_msg_valid = 1'b0;
    endcase
end


///////////////////////////////////////////////////
/////////////////o_tx_sub_state MUXING/////////////
///////////////////////////////////////////////////
always @ (*) begin
    case (CS)
        MBINIT: begin
            o_tx_sub_state = sub_state_MBINIT;
        end
        MBTRAIN: begin
            o_tx_sub_state = sub_state_MBTRAIN;
        end
        default: o_tx_sub_state = 0;
    endcase
end

///////////////////////////////////////////////////
/////////////////o_Functional_Lanes_out_tx MUXING/////////////
///////////////////////////////////////////////////
always @ (*) begin
    case (CS)
        MBINIT: begin
            o_Functional_Lanes_out_tx = MBINIT_tx_Functional_Lanes_out;
        end
        MBTRAIN: begin
            o_Functional_Lanes_out_tx = MBTRAIN_tx_Functional_Lanes_out; 
        end
        default: o_Functional_Lanes_out_tx = 2'b11;
    endcase
end

///////////////////////////////////////////////////
/////////////////o_Functional_Lanes_out_rx MUXING/////////////
///////////////////////////////////////////////////
always @ (*) begin
    case (CS)
        MBINIT: begin
            o_Functional_Lanes_out_rx = MBINIT_rx_Functional_Lanes_out;
        end
        MBTRAIN: begin
            o_Functional_Lanes_out_rx = MBTRAIN_rx_Functional_Lanes_out; 
        end
        default: o_Functional_Lanes_out_rx = 2'b11;
    endcase
end

///////////////////////////////////////////////////
/////////////////o_encoded_SB_msg MUXING/////////////
///////////////////////////////////////////////////
always @ (*) begin
    case (CS)
        SBINIT: begin
            o_encoded_SB_msg = encoded_SB_msg_SBINIT;
        end
        MBINIT: begin
            o_encoded_SB_msg = encoded_SB_msg_MBINIT;
        end
        MBTRAIN: begin
            o_encoded_SB_msg = encoded_SB_msg_MBTRAIN;
        end
        TRAINERROR_HS: begin
            o_encoded_SB_msg = encoded_SB_msg_TRAINERROR;
        end
        PHYRETRAIN: begin
            o_encoded_SB_msg = encoded_SB_msg_PHYRETRAIN;
        end
        //default: o_encoded_SB_msg = 4'b0000;

    endcase
end

endmodule