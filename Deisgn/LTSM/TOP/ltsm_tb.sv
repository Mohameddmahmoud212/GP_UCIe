`timescale 1ns/1ps

module LTSM_wrapper_tb;

////////////////////////////
//// clock & reset
////////////////////////////
reg i_clk;
reg i_rst_n;

////////////////////////////
//// RDI
////////////////////////////
reg i_lp_linkerror;
reg i_start_training_rdi;
reg i_go_to_phyretrain_ACTIVE;
reg [3:0] i_reciever_ref_voltage;

////////////////////////////
//// point test
////////////////////////////
reg i_tx_point_test_ack;
reg i_rx_point_test_ack;
reg [15:0] i_tx_lanes_result;
reg [15:0] i_rx_lanes_result;
reg [15:0] i_rx_data_bus;
reg i_reset_resolved_state;

////////////////////////////
//// SB
////////////////////////////
reg i_time_out;
reg [3:0] i_decoded_SB_msg;
reg i_sb_busy;
reg i_rx_msg_valid;
reg [2:0] i_rx_msg_info;
reg [15:0] i_sb_data;
reg i_start_receiving_pattern;
reg i_start_pattern_done;
reg i_selfcal_done_ack ;
reg i_rx_cal_done_ack ;

////////////////////////////
//// LTSM
////////////////////////////
reg i_ACTIVE_DONE;
reg i_LINKINIT_DONE;

////////////////////////////
//// pattern modules
////////////////////////////
reg i_Transmitter_initiated_Data_to_CLK_done;
reg [15:0] i_Transmitter_initiated_Data_to_CLK_Result;

reg i_logged_val_result;
reg [15:0] i_logged_lane_id_result;

reg i_valid_framing_error;
reg i_REVERSAL_done;
reg i_CLK_Track_done;
reg i_LaneID_Pattern_done;

reg [2:0] i_logged_clk_result;

reg i_VAL_Pattern_done;

////////////////////////////
//// outputs
////////////////////////////
wire [3:0] o_encoded_SB_msg;
wire o_tx_msg_valid;
wire [3:0] o_tx_sub_state;
wire [15:0] o_tx_data_bus;
wire [2:0] o_tx_msg_info;
wire o_tx_data_valid;
wire o_start_pattern_req;

wire [1:0] o_MBINIT_REVERSALMB_LaneID_Pattern_En;
wire o_MBINIT_REVERSALMB_ApplyReversal_En;
wire [1:0] o_Clear_Pattern_Comparator;

wire [1:0] o_Functional_Lanes_out_tx;
wire [1:0] o_Functional_Lanes_out_rx;

wire o_Final_ClockMode;
wire o_Final_ClockPhase;

wire o_enable_cons;
wire o_clear_clk_detection;

wire o_MBINIT_REPAIRCLK_Pattern_En;
wire o_MBINIT_REPAIRVAL_Pattern_En;

wire o_Transmitter_initiated_Data_to_CLK_en;
wire o_lfsr_or_perlane_Transmitter_initiated_Data_to_CLK;
wire o_mainband_Transmitter_initiated_Data_to_CLK;

wire o_timeout_disable;

wire [3:0] o_reciever_ref_voltage;
wire [3:0] o_pi_step;

wire o_tx_mainband_or_valtrain_test;

wire o_rx_mainband_or_valtrain_test;
wire o_rx_pt_en;

wire o_tx_eye_width_sweep_en;

wire [2:0] o_curret_operating_speed;

wire o_pl_trainerror;

///////////////////////////////////////////////////////
//////////////// DUT /////////////////////////////////
///////////////////////////////////////////////////////

LTSM_wrapper dut (

.i_clk(i_clk),
.i_rst_n(i_rst_n),

.i_lp_linkerror(i_lp_linkerror),
.i_start_training_rdi(i_start_training_rdi),
.i_go_to_phyretrain_ACTIVE(i_go_to_phyretrain_ACTIVE),
.i_reciever_ref_voltage(i_reciever_ref_voltage),

.i_tx_point_test_ack(i_tx_point_test_ack),
.i_rx_point_test_ack(i_rx_point_test_ack),

.i_tx_lanes_result(i_tx_lanes_result),
.i_rx_lanes_result(i_rx_lanes_result),

.i_rx_data_bus(i_rx_data_bus),

.i_reset_resolved_state(i_reset_resolved_state),

.i_time_out(i_time_out),
.i_decoded_SB_msg(i_decoded_SB_msg),
.i_sb_busy(i_sb_busy),
.i_rx_msg_valid(i_rx_msg_valid),
.i_rx_msg_info(i_rx_msg_info),
.i_start_receiving_pattern(i_start_receiving_pattern),
.i_start_pattern_done(i_start_pattern_done),
.i_selfcal_done_ack(i_selfcal_done_ack),
.i_rx_cal_done_ack(i_rx_cal_done_ack),

.i_ACTIVE_DONE(i_ACTIVE_DONE),
.i_LINKINIT_DONE(i_LINKINIT_DONE),

.i_Transmitter_initiated_Data_to_CLK_done(i_Transmitter_initiated_Data_to_CLK_done),
.i_Transmitter_initiated_Data_to_CLK_Result(i_Transmitter_initiated_Data_to_CLK_Result),

.i_logged_val_result(i_logged_val_result),
.i_logged_lane_id_result(i_logged_lane_id_result),

.i_valid_framing_error(i_valid_framing_error),
.i_REVERSAL_done(i_REVERSAL_done),
.i_CLK_Track_done(i_CLK_Track_done),
.i_LaneID_Pattern_done(i_LaneID_Pattern_done),

.i_logged_clk_result(i_logged_clk_result),
.i_VAL_Pattern_done(i_VAL_Pattern_done),

.o_encoded_SB_msg(o_encoded_SB_msg),
.o_tx_msg_valid(o_tx_msg_valid),
.o_tx_sub_state(o_tx_sub_state),
.o_tx_data_bus(o_tx_data_bus),
.o_tx_msg_info(o_tx_msg_info),
.o_tx_data_valid(o_tx_data_valid),
.o_start_pattern_req(o_start_pattern_req),

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

///////////////////////////////////////////////////////
//////////////// CLOCK ///////////////////////////////
///////////////////////////////////////////////////////
initial i_clk = 1'b0;
  
always #5 i_clk = ~i_clk;

///////////////////////////////////////////////////////
//////////////// TEST SEQUENCE ///////////////////////
///////////////////////////////////////////////////////

task initial_defaults;
    i_rst_n = 0;
    i_lp_linkerror = 0;
    i_start_training_rdi= 0;
    i_go_to_phyretrain_ACTIVE= 0;
    i_reciever_ref_voltage= 0;
    i_tx_point_test_ack= 0;
    i_rx_point_test_ack= 0;
    i_tx_lanes_result= 0;
    i_rx_lanes_result= 0;
    i_rx_data_bus= 0;
    i_reset_resolved_state= 0;
    i_time_out= 0;
    i_decoded_SB_msg= 0;
    i_sb_busy= 0;
    i_rx_msg_valid= 0;
    i_rx_msg_info= 0;
    i_sb_data= 0;
    i_start_receiving_pattern= 0;
    i_start_pattern_done= 0;
    i_ACTIVE_DONE= 0;
    i_LINKINIT_DONE= 0;
    i_Transmitter_initiated_Data_to_CLK_done= 0;
    i_Transmitter_initiated_Data_to_CLK_Result= 0;
    i_logged_val_result= 0;
    i_logged_lane_id_result= 0;
    i_valid_framing_error= 0;
    i_REVERSAL_done= 0;
    i_CLK_Track_done= 0;
    i_LaneID_Pattern_done= 0;
    i_logged_clk_result= 0;
    i_VAL_Pattern_done= 0;
    i_selfcal_done_ack = 0;
    i_rx_cal_done_ack = 0;

endtask



typedef enum{   RESET,FINISH_RESET,SBINIT,MBINIT,MBTRAIN,LINKINIT,ACTIVE ,PHYRETRAIN, TRAINERROR_HS  } states_enum;
string CS_tb_wp_ltsm,NS_tb_wp_ltsm;

always@(*)begin
    case(dut.CS) 

        0:CS_tb_wp_ltsm="RESET";
        1:CS_tb_wp_ltsm="FINISH_RESET";
        2:CS_tb_wp_ltsm="SBINIT";
        3:CS_tb_wp_ltsm="MBINIT";
        4:CS_tb_wp_ltsm="MBTRAIN";
        5:CS_tb_wp_ltsm="LINKINIT";
        6:CS_tb_wp_ltsm="ACTIVE";
        7:CS_tb_wp_ltsm="PHYRETRAIN";
        8:CS_tb_wp_ltsm="TRAINERROR_HS";
    endcase
 end


 
always@(*)begin
    case(dut.NS) 
        0:NS_tb_wp_ltsm="RESET";
        1:NS_tb_wp_ltsm="FINISH_RESET";
        2:NS_tb_wp_ltsm="SBINIT";
        3:NS_tb_wp_ltsm="MBINIT";
        4:NS_tb_wp_ltsm="MBTRAIN";
        5:NS_tb_wp_ltsm="LINKINIT";
        6:NS_tb_wp_ltsm="ACTIVE";
        7:NS_tb_wp_ltsm="PHYRETRAIN";
        8:NS_tb_wp_ltsm="TRAINERROR_HS";
    endcase
 end


task wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            @(negedge i_clk);
        end
    end
endtask



task reset;
    i_rst_n = 0;
    wait_cycles(5);
    i_rst_n = 1;
endtask


  
task SBINIT_TEST;
    begin
        i_sb_busy = 1;
        $strobe("SB IS BUSY AT TIME = %0t",$time);
        $display("Normal flow task started at time = %0t" ,$time);  
       
        

    end
endtask
/////////////////////////////////////////////////
            //MBINIT//
always @(posedge i_clk)
if(dut.CS==3)
$display("MBINIT sub=%0d tx_valid=%0b busy=%0b",
dut.sub_state_MBINIT,dut.o_tx_msg_valid,i_sb_busy);

integer busy_counter;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        i_sb_busy <= 0;
        busy_counter <= 0;
    end
    else begin
        if( busy_counter==0) begin
            i_sb_busy <= 1;
            busy_counter <= 3;
        end
        else if(busy_counter > 0) begin
            busy_counter <= busy_counter - 1;
            if(busy_counter == 1)
                i_sb_busy <= 0;
        end
    end
end
///////////////////////////////////////////
////////   MBINIT  ///////////////////////////////
task automatic run_mbinit;

integer timeout;

begin

$display("----- MBINIT TEST START -----");

/////////////////////////////////////////////////
// PARAM STAGE
/////////////////////////////////////////////////

timeout = 0;
while(!dut.o_tx_msg_valid && timeout < 50) begin
    wait_cycles(1);
    timeout = timeout + 1;
end
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'h1;
i_rx_data_bus    = 16'h0123;

wait_cycles(6);

i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'h2;
i_rx_data_bus    = 16'h0123;

wait_cycles(6);
i_rx_data_bus    = 16'h0000;
i_rx_msg_valid   = 0;

/////////////////////////////////////////////////
// CAL STAGE
/////////////////////////////////////////////////

timeout = 0;
while(!dut.o_tx_msg_valid && timeout < 50) begin
    wait_cycles(1);
    timeout = timeout + 1;
end

i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'h1;
wait_cycles(5);
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'h2;

wait_cycles(1);
i_rx_msg_valid   = 0;

/////////////////////////////////////////////////
// REPAIRCLK
/////////////////////////////////////////////////
// waiting respond INIT_REQ from DUT
timeout = 0;
while(!(dut.o_encoded_SB_msg == 4'b0001) && timeout < 50) begin
    wait_cycles(1);
    timeout = timeout + 1;
end
$display("INIT_REQ received: %0h", dut.o_encoded_SB_msg);
// sending request
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0001; // init_req
wait_cycles(5);


// respond INIT_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0010; // init_resp
wait_cycles(5);
i_rx_msg_valid   = 0;
$display("INIT_RESP sent");
wait_cycles(2);

i_CLK_Track_done    = 1;

wait_cycles(5);
i_CLK_Track_done    = 0;


wait_cycles(2);
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0011; // result_req
wait_cycles(2);


// waiting RESULT_REQ

i_logged_clk_result = 3'b111;
i_rx_msg_info = 3'b111;

// respond RESULT_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0100; // result_resp
wait_cycles(5);
i_rx_msg_valid   = 0;
$display("RESULT_RESP sent");

wait_cycles(5);
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0101; // Done_REQ

wait_cycles(5);
i_rx_msg_valid   = 0;
// waiting DONE_REQ
timeout = 0;
while(!(dut.o_encoded_SB_msg == 4'b0110) && timeout < 50) begin
    wait_cycles(1);
    timeout = timeout + 1;
end
$display("DONE_REQ received: %0h", dut.o_encoded_SB_msg);

//  DONE_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0110; // done_resp
wait_cycles(2);
i_rx_msg_valid   = 0;
$display("DONE_RESP sent");
wait_cycles(10);



/////////////////////////////////////////////////
// REPAIRVAL
/////////////////////////////////////////////////
// waiting respond INIT_REQ from DUT
timeout = 0;
while(!(dut.o_encoded_SB_msg == 4'b0001) && timeout < 50) begin
    wait_cycles(1);
    timeout = timeout + 1;
end
$display("INIT_REQ received: %0h", dut.o_encoded_SB_msg);
// sending request
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0001; // init_req
wait_cycles(5);


// respond INIT_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0010; // init_resp
wait_cycles(5);
i_rx_msg_valid   = 0;
$display("INIT_RESP sent");
wait_cycles(2);


i_VAL_Pattern_done  = 1;

wait_cycles(2);
i_VAL_Pattern_done  = 0;

wait_cycles(2);
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0011; // result_req
wait_cycles(2);


// waiting RESULT_REQ
i_logged_val_result = 1;


// respond RESULT_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0100; // result_resp
wait_cycles(5);
i_rx_msg_valid   = 0;
$display("RESULT_RESP sent");

wait_cycles(5);
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0101; // result_resp

wait_cycles(5);
i_rx_msg_valid   = 0;
// waiting DONE_REQ
timeout = 0;
while(!(dut.o_encoded_SB_msg == 4'b0110) && timeout < 50) begin
    wait_cycles(1);
    timeout = timeout + 1;
end
$display("DONE_REQ received: %0h", dut.o_encoded_SB_msg);

//  DONE_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0110; // done_resp
wait_cycles(2);
i_rx_msg_valid   = 0;
$display("DONE_RESP sent");
wait_cycles(10);







/////////////////////////////////////////////////
// REVERSALMB
/////////////////////////////////////////////////

$display("----- REVERSALMB TEST START -----");

/////////////////////////////////////////////////
// INIT STAGE
/////////////////////////////////////////////////

// INIT_REQ
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0001;
wait_cycles(3);

// INIT_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0010;
wait_cycles(3);

i_rx_msg_valid = 0;

/////////////////////////////////////////////////
// CLEAR ERROR
/////////////////////////////////////////////////

// CLEAR_ERROR_REQ
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0011;
wait_cycles(3);

// CLEAR_ERROR_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0100;
wait_cycles(3);

i_rx_msg_valid = 0;

/////////////////////////////////////////////////
// LANEID PATTERN
/////////////////////////////////////////////////

wait_cycles(5);

i_LaneID_Pattern_done = 1;
wait_cycles(3);
i_LaneID_Pattern_done = 0;

/////////////////////////////////////////////////
// RESULT
/////////////////////////////////////////////////

// RESULT_REQ
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0101;
wait_cycles(3);

i_rx_data_bus = 16'h00FF;
//i_logged_lane_id_result = 16'h00FF;

// RESULT_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0110;
wait_cycles(3);

i_rx_msg_valid = 0;

/////////////////////////////////////////////////
// APPLY REVERSAL
/////////////////////////////////////////////////

    wait_cycles(5);
    i_REVERSAL_done = 1;
    wait_cycles(3);
    i_REVERSAL_done = 0;

/////////////////////////////////////////////////
// DONE
/////////////////////////////////////////////////

// DONE_REQ
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0111;
wait_cycles(3);

// DONE_RESP
i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b1000;
wait_cycles(3);

i_rx_msg_valid = 0;

wait_cycles(10);

$display("----- REVERSALMB TEST END -----");



/////////////////////////////////////////////////
// REPAIRMB TEST SEQUENCE
/////////////////////////////////////////////////

/////////////////////////////////////////////////
// START
/////////////////////////////////////////////////

i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0001; // START_REQ
wait_cycles(3);

i_decoded_SB_msg = 4'b0010; // START_RESP
wait_cycles(3);

i_rx_msg_valid = 0;

/////////////////////////////////////////////////
// DATA CLOCK
/////////////////////////////////////////////////

wait_cycles(3);
i_Transmitter_initiated_Data_to_CLK_done = 1;
i_Transmitter_initiated_Data_to_CLK_Result = 16'hFFFF;

wait_cycles(3);

/////////////////////////////////////////////////
// DEGRADE
/////////////////////////////////////////////////

i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0101; // APPLY_DEGRADE_REQ
wait_cycles(3);

i_decoded_SB_msg = 4'b0110; // APPLY_DEGRADE_RESP
wait_cycles(3);

i_rx_msg_valid = 0;

/////////////////////////////////////////////////
// END
/////////////////////////////////////////////////

i_rx_msg_valid   = 1;
i_decoded_SB_msg = 4'b0011; // END_REQ
wait_cycles(3);

i_decoded_SB_msg = 4'b0100; // END_RESP
wait_cycles(10);

i_rx_msg_valid = 1;
i_decoded_SB_msg = 4'b0011; // END_REQ
wait_cycles(5);




end
endtask
task partner_sideband_message(input [3:0] msg);
    begin
      @(negedge i_clk);
      i_decoded_SB_msg = msg;
      i_rx_msg_valid   = 1'b1;
      @(negedge i_clk);
      i_rx_msg_valid   = 1'b0;
      i_decoded_SB_msg = 4'b0000;
    end
  endtask
///////////////////////////////////////////////////
////////mbtrain test 
////////////////////////////
            task automatic run_mbtrain;
                    begin

                    $display("[%0t] MBTRAIN ENABLED", $time);
                    wait_cycles(2);

                    // ------------------------------------------------------------
                    // START_REQ = 0001
                    // START_RSP = 0010
                    // END_REQ   = 0011
                    // END_RSP   = 0100
                    // ------------------------------------------------------------
                    /////////////////////////////////////////////////
                    // vref cal 
                    /////////////////////////////////////////////////
                    partner_sideband_message(4'b0001);//come from the sidband interface to receiver 
                    wait_cycles(2);
                    partner_sideband_message(4'b0010);
                    wait_cycles(3);
                    i_tx_point_test_ack = 1'b1; // TX done
                    i_rx_point_test_ack = 1'b1; // RX done
                    i_reciever_ref_voltage = 4'd8 ;
                    wait_cycles(2);
                    i_tx_point_test_ack = 1'b0;
                    i_rx_point_test_ack = 1'b0;
                    wait_cycles(3);
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    /////////////////////////////////////////////////
                    // data_vref  
                    /////////////////////////////////////////////////

                    partner_sideband_message(4'b0001);//come from the sidband interface to receiver 
                    wait_cycles(2);
                    partner_sideband_message(4'b0010);
                    wait_cycles(2);
                    i_tx_point_test_ack = 1'b1; // TX done
                    i_rx_point_test_ack = 1'b1; // RX done
                    i_reciever_ref_voltage = 4'd8 ;
                    wait_cycles(2);
                    i_tx_point_test_ack = 1'b0;
                    i_rx_point_test_ack      = 1'b0;
                    wait_cycles(3);
                    partner_sideband_message(4'b0011);
                    wait_cycles(2);
                    partner_sideband_message(4'b0100);
                    wait_cycles(3);
                    /////////////////////////////////////////////////
                    // speed_idle  
                    /////////////////////////////////////////////////

                    i_selfcal_done_ack = 1 ;
                    partner_sideband_message(4'b0011);
                    wait_cycles(2);
                    wait_cycles(8);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    /////////////////////////////////////////////////
                    // tx_self_cal 
                    /////////////////////////////////////////////////

                    i_selfcal_done_ack = 1 ;
                    partner_sideband_message(4'b0011);
                    wait_cycles(2);
                    wait_cycles(8);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    i_selfcal_done_ack = 0;
                    /////////////////////////////////////////////////
                    // rx_self_cal 
                    /////////////////////////////////////////////////
                    partner_sideband_message(4'b0001);
                    wait_cycles(3);
                    partner_sideband_message(4'b0010);
                    i_rx_cal_done_ack = 1 ;
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    i_rx_cal_done_ack = 0 ;

                    /////////////////////////////////////////////////
                    // val_train center cal 
                    /////////////////////////////////////////////////
                    partner_sideband_message(4'b0001);
                    wait_cycles(3);
                    partner_sideband_message(4'b0010);
                    i_tx_point_test_ack = 1 ;
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);

                    /////////////////////////////////////////////////
                    // val_train_vref  cal 
                    /////////////////////////////////////////////////

                    partner_sideband_message(4'b0001);//come from the sidband interface to receiver 
                    wait_cycles(2);
                    partner_sideband_message(4'b0010);
                    wait_cycles(3);
                    i_tx_point_test_ack = 1'b1; // TX done
                    i_rx_point_test_ack = 1'b1; // RX done
                    i_reciever_ref_voltage = 4'd8 ;
                    wait_cycles(2);
                    i_tx_point_test_ack = 1'b0;
                    i_rx_point_test_ack = 1'b0;
                    wait_cycles(3);
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    /////////////////////////////////////////////////
                    // train center cal ack1
                    /////////////////////////////////////////////////
                    partner_sideband_message(4'b0001);
                    wait_cycles(3);
                    partner_sideband_message(4'b0010);
                    i_tx_point_test_ack = 1 ;
                    wait_cycles(3);
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    wait_cycles(5);

                    /////////////////////////////////////////////////
                    // data_train_vref_
                    /////////////////////////////////////////////////
                    partner_sideband_message(4'b0001);//come from the sidband interface to receiver 
                    wait_cycles(2);
                    partner_sideband_message(4'b0010);
                    wait_cycles(2);
                    i_tx_point_test_ack = 1'b1; // TX done
                    i_rx_point_test_ack = 1'b1; // RX done
                    i_reciever_ref_voltage = 4'd8 ;
                    wait_cycles(2);
                    i_tx_point_test_ack = 1'b0;
                    i_rx_point_test_ack      = 1'b0;
                    wait_cycles(3);
                    partner_sideband_message(4'b0011);
                    wait_cycles(2);
                    partner_sideband_message(4'b0100);
                    wait_cycles(3);
                    /////////////////////////////////////////////////
                    // RX_deskew
                    /////////////////////////////////////////////////
                    partner_sideband_message(4'b0001);
                    wait_cycles(3);
                    partner_sideband_message(4'b0010);
                    i_rx_cal_done_ack = 1 ;
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(5);
                    i_rx_cal_done_ack = 0 ;
                    /////////////////////////////////////////////////
                    // train center cal ack2
                    /////////////////////////////////////////////////
                    wait_cycles(2);
                    partner_sideband_message(4'b0001);
                    wait_cycles(3);
                    partner_sideband_message(4'b0010);
                    i_tx_point_test_ack = 1 ;
                    wait_cycles(3);
                    partner_sideband_message(4'b0011);
                    wait_cycles(3);
                    partner_sideband_message(4'b0100);
                    wait_cycles(10);
                    /////////////////////////////////////////////////
                    // linkspeed
                    /////////////////////////////////////////////////
                    //[1] test that every thing are functional adn we do not need repair 
                    partner_sideband_message(4'b0001);
                    i_tx_lanes_result = 16'hffff ;
                    wait_cycles(5);
                    partner_sideband_message(4'b0010);
                    wait_cycles(5);
                    i_tx_point_test_ack = 1 ;
                    
                    partner_sideband_message(4'b1001);
                    wait_cycles(2);
                    wait_cycles(8);
                    partner_sideband_message(4'b1010);
                    wait_cycles(5);
                    
                    
                    //[2] test for next state is repair (the first 8 lanes have problem )
                    // partner_sideband_message(4'b0001);
                    // i_tx_lanes_result = 16'h00ff ;
                    // wait_cycles(5);
                    // partner_sideband_message(4'b0010);
                    // wait_cycles(5);
                    // partner_sideband_message(4'b0100);
                    // wait_cycles(5);
                    // i_tx_point_test_ack = 1 ;
                    
                    // partner_sideband_message(4'b1001);
                    // wait_cycles(2);
                    // wait_cycles(8);
                    // partner_sideband_message(4'b0110);
                    // wait_cycles(2);
                    // wait_cycles(8);
                    
                    //[3] test for phyritrain requsted from the partner 
                    // partner_sideband_message(4'b0001);
                    // i_tx_lanes_result = 16'hffff ;
                    // wait_cycles(5);
                    // partner_sideband_message(4'b0010);
                    // wait_cycles(5);
                    // i_tx_point_test_ack = 1 ;
                    
                    // partner_sideband_message(4'b1011);
                    // wait_cycles(2);
                    // wait_cycles(8);
                    // partner_sideband_message(4'b1010);
                    // wait_cycles(5);
                    // wait_cycles(5);

                    /////////////////////////////////////////////////
                    // repair
                    /////////////////////////////////////////////////
                    // partner_sideband_message(4'b0001);
                    // wait_cycles(3);
                    // partner_sideband_message(4'b0010);
                    // wait_cycles(3);
                    // partner_sideband_message(4'b0011);
                    // wait_cycles(3);
                    // partner_sideband_message(4'b0100);
                    //  wait_cycles(10);
                    // i_en = 1'b0;
                    // wait_cycles(10);
                    // $display("TB PASS.");
                    // $stop;

                    end
            endtask

            task automatic phyretrian;
                    partner_sideband_message(4'b0001);
                    wait_cycles(3);
                    partner_sideband_message(4'b0010);
                    wait_cycles(3);



            endtask


initial begin
    initial_defaults();
    wait_cycles(2);
    reset();
    $display("Current state is %s" , CS_tb_wp_ltsm); //should be reset
    i_rx_msg_valid = 1;  //asssume always 1 
    i_start_training_rdi = 1;
    i_sb_busy = 0;
    wait_cycles(1);
    $display("Current state is %s" , CS_tb_wp_ltsm);  //STATE SHOULD BE finish reset
    wait_cycles(6);//????
    $display("Current state is %s" , CS_tb_wp_ltsm);  //STATE SHOULD BE SBINIT
    i_start_pattern_done = 1;
    wait_cycles(2);
    i_start_pattern_done = 0;
    wait_cycles(3);
    i_decoded_SB_msg = 3; //out of reset msg
    wait_cycles(2);
    i_decoded_SB_msg = 1;
    wait_cycles(2);
    i_decoded_SB_msg = 2;
    wait_cycles(5);
    $display("Current state is %s" , CS_tb_wp_ltsm);  //STATE SHOULD BE MBINIT and SBINIT FINISHED

    /////////////////////////////////////////////////////
    // WAIT UNTIL DUT ENTERS MBINIT
    /////////////////////////////////////////////////////

    while(dut.CS != 3)
        wait_cycles(1);

    $display("Entered MBINIT at time = %0t",$time);

    run_mbinit();
        wait_cycles(10);
    run_mbtrain();
        wait_cycles(5);
    //phyretrian();

        $stop;
    end
endmodule