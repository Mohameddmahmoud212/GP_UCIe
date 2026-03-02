`timescale 1ns/1ps

module tb_speed_idle;

    // clock/reset
    reg clk;
    reg rst_n;

    // DUT inputs
    reg        i_en;

    reg [3:0]  i_decoded_sideband_message;
    reg        i_sideband_valid;
    reg        i_point_test_ack,i_valid_framing_error   ;
    reg [15:0] i_lanes_result ;
    reg       i_first_8_tx_lanes_are_functional ;
    reg       i_second_8_tx_lanes_are_functional ;
    reg       i_comming_from_repair ;
    wire       o_phy_retrain_req_was_sent_or_recived ;
    wire       o_error_req_was_sent_or_received ;
    wire       o_speed_degrade_req_was_sent_or_received ;
    wire       o_repair_req_was_sent_or_received;
        // talking with phyretrain
    wire [1:0] o_phyretrain_error_encoding ;
        // talking with mbtrain controller (local lane status after PT / decision)
    wire       o_local_first_8_lanes_are_functional ;
    wire       o_local_second_8_lanes_are_functional ;
        // talking with point test 

    reg        i_busy_negedge_detected;

    reg        i_algo_done_ack;     // for TX
    wire       o_link_speeed_ack ,o_phy_retrain_req_was_sent_or_received ;

    wire [3:0]  o_sideband_message;
    wire        o_valid;
    wire        o_pt_en;

    initial clk = 1'b0;
    always #5 clk = ~clk;
    // Instantiate DUT
    
    linkspeed_wrapper dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),
        .i_falling_edge_busy(i_busy_negedge_detected),
        .i_valid_framing_error(i_valid_framing_error),
        .i_point_test_ack(i_algo_done_ack),
        .i_lanes_result(i_lanes_result),//
        .i_first_8_tx_lanes_are_functional(i_first_8_tx_lanes_are_functional),//
        .i_second_8_tx_lanes_are_functional(i_second_8_tx_lanes_are_functional),//
        .i_comming_from_repair(i_comming_from_repair),//

        .o_sideband_message(o_sideband_message),
        .o_valid(o_valid),
        .o_link_speeed_ack(o_link_speeed_ack),
        .o_phy_retrain_req_was_sent_or_received(o_phy_retrain_req_was_sent_or_received),//
        .o_error_req_was_sent_or_received(o_error_req_was_sent_or_received),//
        .o_speed_degrade_req_was_sent_or_received(o_speed_degrade_req_was_sent_or_received),//
        .o_repair_req_was_sent_or_received(o_repair_req_was_sent_or_received),//
        .o_phyretrain_error_encoding(o_phyretrain_error_encoding),//
        .o_local_first_8_lanes_are_functional(o_local_first_8_lanes_are_functional),//
        .o_local_second_8_lanes_are_functional(o_local_second_8_lanes_are_functional),//

        .o_point_test_en(o_pt_en)
    );
     task wait_cycles(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(negedge clk);
            end
        end
        endtask
      
      task drive_decoded_msg(input [3:0] msg);
        begin
            @(negedge clk);
            i_decoded_sideband_message = msg;
            i_sideband_valid           = 1'b1;
            @(negedge clk);
            i_sideband_valid           = 1'b0;
            i_decoded_sideband_message = 4'b0000;
        end
        endtask

    initial begin
       
   
        rst_n = 1'b0;
        i_en = 1'b0;
        i_decoded_sideband_message = 4'b0000;
        i_sideband_valid = 1'b0;
        i_busy_negedge_detected = 1'b0;
        i_algo_done_ack = 1'b0;
        i_point_test_ack = 1'b0;
        i_valid_framing_error= 1'b0;
        i_first_8_tx_lanes_are_functional= 1'b0;
        i_second_8_tx_lanes_are_functional= 1'b0;
        i_comming_from_repair= 1'b0;

        wait_cycles(5);
        rst_n = 1'b1;
        wait_cycles(3);
        i_en = 1'b1; // o_sideband_msg = 1

        // ------------------------------------------------------------
        // localparam START_REQ=4'b0001;
        // localparam START_RESP=4'b0010;
        // localparam ERROR_REQ=4'b0011;
        // localparam ERROR_RESP=4'b0100;
        // localparam EXIT_TO_REPAIR_REQ=4'b0101;
        // localparam EXIT_TO_REPAIR_RESP=4'b0110;
        // localparam EXIT_TO_SPEED_DEGRADE_REQ=4'b0111;
        // localparam EXIT_TO_SPEED_DEGRADE_RESP=4'b1000;
        // localparam DONE_REQ=4'b1001;
        // localparam DONE_RESP=4'b1010;
        // localparam EXIT_TO_PHYRETRAIN_REQ=4'b1011;
        // localparam EXIT_TO_PHYRETRAIN_RESP=4'b1100;
        // ------------------------------------------------------------
        i_busy_negedge_detected = 1 'b1 ;
        wait_cycles(10);
        drive_decoded_msg(4'b0001);//come from the sidband interface to receiver 
        wait_cycles(10);
        drive_decoded_msg(4'b0010);
        wait_cycles(10);
        if (o_pt_en != 1'b1) begin
            $display("ERROR: o_pt_en did not assert as expected.");
            $stop;
        end
        wait_cycles(20);
        @(negedge clk);
        i_algo_done_ack = 1'b1; // TX done
        @(negedge clk);
        i_algo_done_ack = 1'b0;
        i_valid_framing_error     = 1'b1;
        wait_cycles(10);
        drive_decoded_msg(4'b1011);
        wait_cycles(10);
        drive_decoded_msg(4'b1100);

        wait_cycles(5);
        $display("o_valvref_ack=%0d" ,o_link_speeed_ack);

        // $display("o_valvref_ack=%0d o_valvref_fail=%0d o_valvref_lane_mask=%h vref_word=%0d",
        //          o_valvref_ack, o_valvref_fail, o_valvref_lane_mask, o_reciever_ref_voltage);

        // if (o_valvref_ack !== 1'b1) begin
        //     $display("ERROR: o_valvref_ack did not assert.");
        //     $stop;
        // end

        // // expected fail=0 and lane_mask=FFFF
        // // if (o_valvref_fail !== 1'b0) begin
        // //     $display("ERROR: o_valvref_fail unexpected.");
        // //     $stop;
        // // end

        // // disable
        // wait_cycles(10);
        i_en = 1'b0;

        wait_cycles(20);
        $display("TB PASS.");
        $stop;
    end

endmodule
