`timescale 1ns/1ps

module ltsm_with_sideband_tb ;

//////////////////////////////////////////////
// CLOCK & RESET
//////////////////////////////////////////////

reg d0_i_clk;
reg d0_i_rst_n;

reg d1_i_clk;
reg d1_i_rst_n;

//////////////////////////////////////////////
// SIDE BAND INPUTS
//////////////////////////////////////////////

reg d0_i_tx_point_sweep_test_en;
reg [1:0] d0_i_tx_point_sweep_test;
reg d0_RXCKSB;
reg d0_RXDATASB;
reg d0_i_pattern_detected;

reg d1_i_tx_point_sweep_test_en;
reg [1:0] d1_i_tx_point_sweep_test;
reg d1_RXCKSB;
reg d1_RXDATASB;
reg d1_i_pattern_detected;

//////////////////////////////////////////////
// SIDE BAND OUTPUTS
//////////////////////////////////////////////

wire d0_TXDATASB;
wire d0_TXCKSB;
wire d0_o_pattern_time_out;
wire d0_o_tx_point_sweep_test_en;
wire [1:0] d0_o_tx_point_sweep_test;

wire d1_TXDATASB;
wire d1_TXCKSB;
wire d1_o_pattern_time_out;
wire d1_o_tx_point_sweep_test_en;
wire [1:0] d1_o_tx_point_sweep_test;

//////////////////////////////////////////////
// LTSM INPUTS
//////////////////////////////////////////////

reg d0_i_lp_linkerror;
reg d0_i_start_training_rdi;
reg d0_i_go_to_phyretrain_ACTIVE;
reg [3:0] d0_i_reciever_ref_voltage;

reg d1_i_lp_linkerror;
reg d1_i_start_training_rdi;
reg d1_i_go_to_phyretrain_ACTIVE;
reg [3:0] d1_i_reciever_ref_voltage;

//////////////////////////////////////////////
// ACKS
//////////////////////////////////////////////

reg d0_i_tx_point_test_ack;
reg d0_i_rx_point_test_ack;
reg d1_i_tx_point_test_ack;
reg d1_i_rx_point_test_ack;

//////////////////////////////////////////////
// LANES RESULT
//////////////////////////////////////////////

reg [15:0] d0_i_tx_lanes_result;
reg [15:0] d0_i_rx_lanes_result;

reg [15:0] d1_i_tx_lanes_result;
reg [15:0] d1_i_rx_lanes_result;

//////////////////////////////////////////////
// CAL DONE
//////////////////////////////////////////////

reg d0_i_selfcal_done_ack;
reg d0_i_rx_cal_done_ack;

reg d1_i_selfcal_done_ack;
reg d1_i_rx_cal_done_ack;

//////////////////////////////////////////////
// CONTROL
//////////////////////////////////////////////

reg d0_i_reset_resolved_state;
reg d0_i_time_out;
reg d0_i_start_receiving_pattern;
reg d0_i_start_pattern_done;

reg d1_i_reset_resolved_state;
reg d1_i_time_out;
reg d1_i_start_receiving_pattern;
reg d1_i_start_pattern_done;

//////////////////////////////////////////////
// ACTIVE & LINK INIT
//////////////////////////////////////////////

reg d0_i_ACTIVE_DONE;
reg d0_i_LINKINIT_DONE;

reg d1_i_ACTIVE_DONE;
reg d1_i_LINKINIT_DONE;

//////////////////////////////////////////////
// POINT TEST
//////////////////////////////////////////////

reg d0_i_Transmitter_initiated_Data_to_CLK_done;
reg [15:0] d0_i_Transmitter_initiated_Data_to_CLK_Result;

reg d1_i_Transmitter_initiated_Data_to_CLK_done;
reg [15:0] d1_i_Transmitter_initiated_Data_to_CLK_Result;

//////////////////////////////////////////////
// LOGGED RESULTS
//////////////////////////////////////////////

reg d0_i_logged_val_result;
reg [15:0] d0_i_logged_lane_id_result;

reg d1_i_logged_val_result;
reg [15:0] d1_i_logged_lane_id_result;

//////////////////////////////////////////////
// REVERSAL
//////////////////////////////////////////////

reg d0_i_valid_framing_error;
reg d0_i_REVERSAL_done;
reg d0_i_CLK_Track_done;
reg d0_i_LaneID_Pattern_done;
reg [2:0] d0_i_logged_clk_result;

reg d1_i_valid_framing_error;
reg d1_i_REVERSAL_done;
reg d1_i_CLK_Track_done;
reg d1_i_LaneID_Pattern_done;
reg [2:0] d1_i_logged_clk_result;

//////////////////////////////////////////////
// PATTERN DONE
//////////////////////////////////////////////

reg d0_i_VAL_Pattern_done;
reg d1_i_VAL_Pattern_done;

//////////////////////////////////////////////
// OUTPUTS
//////////////////////////////////////////////

wire [1:0] d0_o_MBINIT_REVERSALMB_LaneID_Pattern_En;
wire d0_o_MBINIT_REVERSALMB_ApplyReversal_En;
wire [1:0] d0_o_Clear_Pattern_Comparator;

wire [1:0] d0_o_Functional_Lanes_out_tx;
wire [1:0] d0_o_Functional_Lanes_out_rx;

wire d0_o_Final_ClockMode;
wire d0_o_Final_ClockPhase;
wire d0_o_enable_cons;
wire d0_o_clear_clk_detection;

wire d0_o_MBINIT_REPAIRCLK_Pattern_En;
wire d0_o_MBINIT_REPAIRVAL_Pattern_En;

wire d0_o_Transmitter_initiated_Data_to_CLK_en;
wire d0_o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK;
wire d0_o_mainband_Transmitter_initiated_Data_to_CLK;

wire d0_o_timeout_disable;
wire [3:0] d0_o_reciever_ref_voltage;
wire [3:0] d0_o_pi_step;

wire d0_o_tx_mainband_or_valtrain_test;
wire d0_o_rx_mainband_or_valtrain_test;
wire d0_o_rx_pt_en;
wire d0_o_tx_eye_width_sweep_en;

wire [2:0] d0_o_curret_operating_speed;
wire d0_o_pl_trainerror;


//////////////////////////////////////////////
// DIE1 OUTPUTS
//////////////////////////////////////////////

wire [1:0] d1_o_MBINIT_REVERSALMB_LaneID_Pattern_En;
wire d1_o_MBINIT_REVERSALMB_ApplyReversal_En;
wire [1:0] d1_o_Clear_Pattern_Comparator;

wire [1:0] d1_o_Functional_Lanes_out_tx;
wire [1:0] d1_o_Functional_Lanes_out_rx;

wire d1_o_Final_ClockMode;
wire d1_o_Final_ClockPhase;
wire d1_o_enable_cons;
wire d1_o_clear_clk_detection;

wire d1_o_MBINIT_REPAIRCLK_Pattern_En;
wire d1_o_MBINIT_REPAIRVAL_Pattern_En;

wire d1_o_Transmitter_initiated_Data_to_CLK_en;
wire d1_o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK;
wire d1_o_mainband_Transmitter_initiated_Data_to_CLK;

wire d1_o_timeout_disable;
wire [3:0] d1_o_reciever_ref_voltage;
wire [3:0] d1_o_pi_step;

wire d1_o_tx_mainband_or_valtrain_test;
wire d1_o_rx_mainband_or_valtrain_test;
wire d1_o_rx_pt_en;
wire d1_o_tx_eye_width_sweep_en;

wire [2:0] d1_o_curret_operating_speed;
wire d1_o_pl_trainerror;


    initial begin
        d0_i_clk = 0;
        forever begin
            #10  d0_i_clk = ~d0_i_clk;
        end
    end

     initial begin
        d1_i_clk = 0;
        forever begin
            #10  d1_i_clk = ~d1_i_clk;
        end
    end
ltsm_with_sideband_top die0_dut(

.i_clk(d0_i_clk),
.i_rst_n(d0_i_rst_n),
.i_tx_point_sweep_test_en(d0_i_tx_point_sweep_test_en),
.i_tx_point_sweep_test(d0_i_tx_point_sweep_test),
.RXCKSB(d1_TXCKSB),
.RXDATASB(d1_TXDATASB),
.i_pattern_detected(d0_i_pattern_detected),
.i_lp_linkerror(d0_i_lp_linkerror),
.i_start_training_rdi(d0_i_start_training_rdi),
.i_go_to_phyretrain_ACTIVE(d0_i_go_to_phyretrain_ACTIVE),
.i_reciever_ref_voltage(d0_i_reciever_ref_voltage),
.i_tx_point_test_ack(d0_i_tx_point_test_ack),
.i_rx_point_test_ack(d0_i_rx_point_test_ack),
.i_tx_lanes_result(d0_i_tx_lanes_result),
.i_rx_lanes_result(d0_i_rx_lanes_result),
.i_selfcal_done_ack(d0_i_selfcal_done_ack),
.i_rx_cal_done_ack(d0_i_rx_cal_done_ack),
.i_reset_resolved_state(d0_i_reset_resolved_state),
.i_time_out(d0_i_time_out),
.i_start_receiving_pattern(d0_i_start_receiving_pattern),
.i_start_pattern_done(d0_i_start_pattern_done),
.i_ACTIVE_DONE(d0_i_ACTIVE_DONE),
.i_LINKINIT_DONE(d0_i_LINKINIT_DONE),
.i_Transmitter_initiated_Data_to_CLK_done(d0_i_Transmitter_initiated_Data_to_CLK_done),
.i_Transmitter_initiated_Data_to_CLK_Result(d0_i_Transmitter_initiated_Data_to_CLK_Result),
.i_logged_val_result(d0_i_logged_val_result),
.i_logged_lane_id_result(d0_i_logged_lane_id_result),
.i_valid_framing_error(d0_i_valid_framing_error),
.i_REVERSAL_done(d0_i_REVERSAL_done),
.i_CLK_Track_done(d0_i_CLK_Track_done),
.i_LaneID_Pattern_done(d0_i_LaneID_Pattern_done),
.i_logged_clk_result(d0_i_logged_clk_result),
.i_VAL_Pattern_done(d0_i_VAL_Pattern_done),

.TXDATASB(d0_TXDATASB),
.o_pattern_time_out(d0_o_pattern_time_out),
.TXCKSB(d0_TXCKSB),
.o_tx_point_sweep_test_en(d0_o_tx_point_sweep_test_en),
.o_tx_point_sweep_test(d0_o_tx_point_sweep_test),
.o_MBINIT_REVERSALMB_LaneID_Pattern_En(d0_o_MBINIT_REVERSALMB_LaneID_Pattern_En),
.o_MBINIT_REVERSALMB_ApplyReversal_En(d0_o_MBINIT_REVERSALMB_ApplyReversal_En),
.o_Clear_Pattern_Comparator(d0_o_Clear_Pattern_Comparator),
.o_Functional_Lanes_out_tx(d0_o_Functional_Lanes_out_tx),
.o_Functional_Lanes_out_rx(d0_o_Functional_Lanes_out_rx),
.o_Final_ClockMode(d0_o_Final_ClockMode),
.o_Final_ClockPhase(d0_o_Final_ClockPhase),
.o_enable_cons(d0_o_enable_cons),
.o_clear_clk_detection(d0_o_clear_clk_detection),
.o_MBINIT_REPAIRCLK_Pattern_En(d0_o_MBINIT_REPAIRCLK_Pattern_En),
.o_MBINIT_REPAIRVAL_Pattern_En(d0_o_MBINIT_REPAIRVAL_Pattern_En),
.o_Transmitter_initiated_Data_to_CLK_en(d0_o_Transmitter_initiated_Data_to_CLK_en),
.o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK(d0_o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK),
.o_mainband_Transmitter_initiated_Data_to_CLK(d0_o_mainband_Transmitter_initiated_Data_to_CLK),
.o_timeout_disable(d0_o_timeout_disable),
.o_reciever_ref_voltage(d0_o_reciever_ref_voltage),
.o_pi_step(d0_o_pi_step),
.o_tx_mainband_or_valtrain_test(d0_o_tx_mainband_or_valtrain_test),
.o_rx_mainband_or_valtrain_test(d0_o_rx_mainband_or_valtrain_test),
.o_rx_pt_en(d0_o_rx_pt_en),
.o_tx_eye_width_sweep_en(d0_o_tx_eye_width_sweep_en),
.o_curret_operating_speed(d0_o_curret_operating_speed),
.o_pl_trainerror(d0_o_pl_trainerror)

);
ltsm_with_sideband_top die1_dut(

.i_clk(d0_i_clk), // assume that the dies have the same clock for now 
.i_rst_n(d1_i_rst_n),
.i_tx_point_sweep_test_en(d1_i_tx_point_sweep_test_en),
.i_tx_point_sweep_test(d1_i_tx_point_sweep_test),
.RXCKSB(d0_TXCKSB),
.RXDATASB(d0_TXDATASB),
.i_pattern_detected(d1_i_pattern_detected),
.i_lp_linkerror(d1_i_lp_linkerror),
.i_start_training_rdi(d1_i_start_training_rdi),
.i_go_to_phyretrain_ACTIVE(d1_i_go_to_phyretrain_ACTIVE),
.i_reciever_ref_voltage(d1_i_reciever_ref_voltage),
.i_tx_point_test_ack(d1_i_tx_point_test_ack),
.i_rx_point_test_ack(d1_i_rx_point_test_ack),
.i_tx_lanes_result(d1_i_tx_lanes_result),
.i_rx_lanes_result(d1_i_rx_lanes_result),
.i_selfcal_done_ack(d1_i_selfcal_done_ack),
.i_rx_cal_done_ack(d1_i_rx_cal_done_ack),
.i_reset_resolved_state(d1_i_reset_resolved_state),
.i_time_out(d1_i_time_out),
.i_start_receiving_pattern(d1_i_start_receiving_pattern),
.i_start_pattern_done(d1_i_start_pattern_done),
.i_ACTIVE_DONE(d1_i_ACTIVE_DONE),
.i_LINKINIT_DONE(d1_i_LINKINIT_DONE),
.i_Transmitter_initiated_Data_to_CLK_done(d1_i_Transmitter_initiated_Data_to_CLK_done),
.i_Transmitter_initiated_Data_to_CLK_Result(d1_i_Transmitter_initiated_Data_to_CLK_Result),
.i_logged_val_result(d1_i_logged_val_result),
.i_logged_lane_id_result(d1_i_logged_lane_id_result),
.i_valid_framing_error(d1_i_valid_framing_error),
.i_REVERSAL_done(d1_i_REVERSAL_done),
.i_CLK_Track_done(d1_i_CLK_Track_done),
.i_LaneID_Pattern_done(d1_i_LaneID_Pattern_done),
.i_logged_clk_result(d1_i_logged_clk_result),
.i_VAL_Pattern_done(d1_i_VAL_Pattern_done),

.TXDATASB(d1_TXDATASB),
.o_pattern_time_out(d1_o_pattern_time_out),
.TXCKSB(d1_TXCKSB),
.o_tx_point_sweep_test_en(d1_o_tx_point_sweep_test_en),
.o_tx_point_sweep_test(d1_o_tx_point_sweep_test),
.o_MBINIT_REVERSALMB_LaneID_Pattern_En(d1_o_MBINIT_REVERSALMB_LaneID_Pattern_En),
.o_MBINIT_REVERSALMB_ApplyReversal_En(d1_o_MBINIT_REVERSALMB_ApplyReversal_En),
.o_Clear_Pattern_Comparator(d1_o_Clear_Pattern_Comparator),
.o_Functional_Lanes_out_tx(d1_o_Functional_Lanes_out_tx),
.o_Functional_Lanes_out_rx(d1_o_Functional_Lanes_out_rx),
.o_Final_ClockMode(d1_o_Final_ClockMode),
.o_Final_ClockPhase(d1_o_Final_ClockPhase),
.o_enable_cons(d1_o_enable_cons),
.o_clear_clk_detection(d1_o_clear_clk_detection),
.o_MBINIT_REPAIRCLK_Pattern_En(d1_o_MBINIT_REPAIRCLK_Pattern_En),
.o_MBINIT_REPAIRVAL_Pattern_En(d1_o_MBINIT_REPAIRVAL_Pattern_En),
.o_Transmitter_initiated_Data_to_CLK_en(d1_o_Transmitter_initiated_Data_to_CLK_en),
.o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK(d1_o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK),
.o_mainband_Transmitter_initiated_Data_to_CLK(d1_o_mainband_Transmitter_initiated_Data_to_CLK),
.o_timeout_disable(d1_o_timeout_disable),
.o_reciever_ref_voltage(d1_o_reciever_ref_voltage),
.o_pi_step(d1_o_pi_step),
.o_tx_mainband_or_valtrain_test(d1_o_tx_mainband_or_valtrain_test),
.o_rx_mainband_or_valtrain_test(d1_o_rx_mainband_or_valtrain_test),
.o_rx_pt_en(d1_o_rx_pt_en),
.o_tx_eye_width_sweep_en(d1_o_tx_eye_width_sweep_en),
.o_curret_operating_speed(d1_o_curret_operating_speed),
.o_pl_trainerror(d1_o_pl_trainerror)

);

 task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(negedge d0_i_clk);
            end
        end
endtask
task reset_die0_inputs;
begin
d0_i_rst_n = 0 ;
d0_i_tx_point_sweep_test_en = 0;
d0_i_tx_point_sweep_test = 0;
d0_RXCKSB = 0;
d0_RXDATASB = 0;
d0_i_pattern_detected = 0;

d0_i_lp_linkerror = 0;
d0_i_start_training_rdi = 0;
d0_i_go_to_phyretrain_ACTIVE = 0;
d0_i_reciever_ref_voltage = 0;

d0_i_tx_point_test_ack = 0;
d0_i_rx_point_test_ack = 0;

d0_i_tx_lanes_result = 0;
d0_i_rx_lanes_result = 0;

d0_i_selfcal_done_ack = 0;
d0_i_rx_cal_done_ack = 0;

d0_i_reset_resolved_state = 0;
d0_i_time_out = 0;
d0_i_start_receiving_pattern = 0;
d0_i_start_pattern_done = 0;

d0_i_ACTIVE_DONE = 0;
d0_i_LINKINIT_DONE = 0;

d0_i_Transmitter_initiated_Data_to_CLK_done = 0;
d0_i_Transmitter_initiated_Data_to_CLK_Result = 0;

d0_i_logged_val_result = 0;
d0_i_logged_lane_id_result = 0;

d0_i_valid_framing_error = 0;
d0_i_REVERSAL_done = 0;
d0_i_CLK_Track_done = 0;
d0_i_LaneID_Pattern_done = 0;
d0_i_logged_clk_result = 0;

d0_i_VAL_Pattern_done = 0;

end
endtask
task reset_die1_inputs;
begin
d1_i_rst_n = 0 ;
d1_i_tx_point_sweep_test_en = 0;
d1_i_tx_point_sweep_test = 0;
d1_i_pattern_detected = 0;

d1_i_lp_linkerror = 0;
d1_i_start_training_rdi = 0;
d1_i_go_to_phyretrain_ACTIVE = 0;
d1_i_reciever_ref_voltage = 0;

d1_i_tx_point_test_ack = 0;
d1_i_rx_point_test_ack = 0;

d1_i_tx_lanes_result = 0;
d1_i_rx_lanes_result = 0;

d1_i_selfcal_done_ack = 0;
d1_i_rx_cal_done_ack = 0;

d1_i_reset_resolved_state = 0;
d1_i_time_out = 0;
d1_i_start_receiving_pattern = 0;
d1_i_start_pattern_done = 0;

d1_i_ACTIVE_DONE = 0;
d1_i_LINKINIT_DONE = 0;

d1_i_Transmitter_initiated_Data_to_CLK_done = 0;
d1_i_Transmitter_initiated_Data_to_CLK_Result = 0;

d1_i_logged_val_result = 0;
d1_i_logged_lane_id_result = 0;

d1_i_valid_framing_error = 0;
d1_i_REVERSAL_done = 0;
d1_i_CLK_Track_done = 0;
d1_i_LaneID_Pattern_done = 0;
d1_i_logged_clk_result = 0;

d1_i_VAL_Pattern_done = 0;

end
endtask
initial begin
    
reset_die1_inputs();
reset_die0_inputs();
wait_cycles(5);

   d0_i_rst_n = 1 ; 
   d1_i_rst_n = 1 ; 
wait_cycles(5);
d0_i_pattern_detected = 1 ;
d1_i_pattern_detected = 1 ;
d0_i_start_training_rdi = 1;
d1_i_start_training_rdi = 1;
wait_cycles(5);
 d0_i_start_pattern_done = 1;
 d1_i_start_pattern_done = 1;
wait_cycles(96);
d0_i_start_pattern_done = 0;
 d1_i_start_pattern_done = 0;
wait_cycles(1000);

$stop;

end



endmodule 