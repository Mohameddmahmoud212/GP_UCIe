`timescale 1ns/1ps
module tb_tx_initiated_point_test_wrapper;

    reg clk;
    reg rst_n;
    reg i_en;
    reg i_mainband_or_valtrain_test;
    reg i_lfsr_or_perlane;
    reg i_pattern_finished;
    reg [15:0] i_comparison_results;
    reg i_valid_result;

    wire [3:0]  o_sideband_message;
    wire        o_valid;
    wire        o_data_valid;
    wire        o_msg_info;
    wire [15:0] o_sideband_data;
    wire        o_val_pattern_en;
    wire [1:0]  o_mainband_pattern_generator_cw;
    wire [1:0]  o_mainband_pattern_compartor_cw;
    wire        o_comparison_valid_en;
    wire        o_test_ack;
    wire        o_valid_result;
    wire [15:0] o_mainband_lanes_result;

    // Instantiate the wrapper
    tx_initiated_point_test_wrapper uut(
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_mainband_or_valtrain_test(i_mainband_or_valtrain_test),
        .i_lfsr_or_perlane(i_lfsr_or_perlane),
        .i_pattern_finished(i_pattern_finished),
        .i_comparison_results(i_comparison_results),
        .i_valid_result(i_valid_result),
        .o_sideband_message(o_sideband_message),
        .o_valid(o_valid),
        .o_data_valid(o_data_valid),
        .o_msg_info(o_msg_info),
        .o_sideband_data(o_sideband_data),
        .o_val_pattern_en(o_val_pattern_en),
        .o_mainband_pattern_generator_cw(o_mainband_pattern_generator_cw),
        .o_mainband_pattern_compartor_cw(o_mainband_pattern_compartor_cw),
        .o_comparison_valid_en(o_comparison_valid_en),
        .o_test_ack(o_test_ack),
        .o_valid_result(o_valid_result),
        .o_mainband_lanes_result(o_mainband_lanes_result)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
        rst_n = 0; i_en = 0; i_mainband_or_valtrain_test = 0; i_lfsr_or_perlane = 0;
        i_pattern_finished = 0; i_comparison_results = 0; i_valid_result = 0;
        #20 rst_n = 1;
        #20 run_point_test_sequence();
        #200 $finish;
    end

    // Task: send pattern
    task run_point_test_sequence;
    begin
        i_en = 1; i_mainband_or_valtrain_test = 0; i_lfsr_or_perlane = 0;

        send_sideband(4'b0001, 16'h0000, 1'b0, 4'b0001);  // START_REQ
        send_sideband(4'b0011, 16'h0000, 1'b0, 4'b0011);  // LFSR_CLEAR_REQ

        // Pattern finished pulse
        i_pattern_finished = 1;
        repeat(4) @(posedge clk);
        i_pattern_finished = 0;

        send_sideband(4'b0101, 16'hA5A5, 1'b1, 4'b0101);  // RESULT_REQ
        send_sideband(4'b0111, 16'hA5A5, 1'b1, 4'b0111);  // END_REQ

        i_en = 0;
        #10;
        if(o_test_ack)
            $display("TEST PASSED at %0t ns", $time);
        else
            $display("TEST FAILED at %0t ns", $time);
    end
    endtask

    task send_sideband(input [3:0] msg, input [15:0] data, input result_valid, input [3:0] expected_msg);
    begin
        i_comparison_results <= data;
        i_valid_result <= result_valid;
        repeat(4) @(posedge clk);
        check_message(expected_msg, msg);
    end
    endtask

    task check_message(input [3:0] expected, input [3:0] actual);
    begin
        if(actual == expected)
            $display("%0t ns: PASS sideband %b", $time, expected);
        else
            $display("%0t ns: FAIL sideband expected %b got %b", $time, expected, actual);
    end
    endtask

    initial begin
        $display("Time\tclk\ten\to_valid\to_test_ack\to_data_valid\to_sideband_msg");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%b\t%h",$time,clk,i_en,o_valid,o_test_ack,o_data_valid,o_sideband_message);
    end

endmodule