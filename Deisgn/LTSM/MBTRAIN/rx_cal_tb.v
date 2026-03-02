`timescale 1ns/1ps

module tb_rx_cal_wrapper;

    // clock/reset
    reg clk;
    reg rst_n;

    // DUT inputs
    reg        i_en;

    reg [3:0]  i_decoded_sideband_message;
    reg        i_sideband_valid;

    reg        i_busy_negedge_detected;

    reg        i_algo_done_ack;     // for TX
    reg        i_test_ack;          // for RX
    reg [15:0] i_rx_lanes_result;

    reg        i_mainband_or_valtrain_test; // VALVREF => 1
    reg  [3:0] i_reciever_ref_voltage ;
    // DUT outputs
    wire [3:0]  o_sideband_message;
    wire        o_valid;
    reg        i_lfsr_or_perlane ;
    wire        o_pt_en;
    wire        o_mainband_or_valtrain_test_out;

    wire        o_valvref_ack;
    wire        o_valvref_fail;
    wire [15:0] o_valvref_lane_mask;

    wire [3:0]  o_reciever_ref_voltage;
     // Clock generation: 100MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;
    // Instantiate DUT
    rx_cal_wrapper dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_decoded_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),
        .i_busy_negedge_detected(i_busy_negedge_detected),
        .i_rx_cal_done_ack(i_algo_done_ack), 

        .o_sideband_message(o_sideband_message),
        .o_valid(o_valid),

        .o_rx_cal_en(o_pt_en),
        
        .o_rx_cal_ack(o_valvref_ack)
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
        i_test_ack      = 1'b0;
        // reset

        i_busy_negedge_detected = 1'b1;
        wait_cycles(5);
        rst_n = 1'b1;
        wait_cycles(3);
        i_en = 1'b1; // o_sideband_msg = 1

        // ------------------------------------------------------------
        // START_REQ = 0001
        // START_RSP = 0010
        // END_REQ   = 0011
        // END_RSP   = 0100
        // ------------------------------------------------------------

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
        i_test_ack      = 1'b1; // RX done
        i_reciever_ref_voltage = 4'd8 ;
        @(negedge clk);
        i_algo_done_ack = 1'b0;
        i_test_ack      = 1'b0;
        wait_cycles(10);
        drive_decoded_msg(4'b0011);
        wait_cycles(10);
        drive_decoded_msg(4'b0100);

        wait_cycles(5);
        $display("o_valvref_ack=%0d" ,o_valvref_ack);

        // $display("o_valvref_ack=%0d o_valvref_fail=%0d o_valvref_lane_mask=%h vref_word=%0d",
        //          o_valvref_ack, o_valvref_fail, o_valvref_lane_mask, o_reciever_ref_voltage);

        if (o_valvref_ack !== 1'b1) begin
            $display("ERROR: o_valvref_ack did not assert.");
            $stop;
        end

        // expected fail=0 and lane_mask=FFFF
        // if (o_valvref_fail !== 1'b0) begin
        //     $display("ERROR: o_valvref_fail unexpected.");
        //     $stop;
        // end

        // disable
        wait_cycles(10);
        i_en = 1'b0;

        wait_cycles(20);
        $display("TB PASS.");
        $stop;
    end

endmodule
//  // Drive a decoded sideband message for 1 cycle + valid
    
