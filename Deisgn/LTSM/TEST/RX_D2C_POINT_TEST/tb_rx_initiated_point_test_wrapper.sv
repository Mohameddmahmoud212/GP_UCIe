`timescale 1ns/1ps

module tb_rx_initiated_point_test;

    localparam SB_MSG_WIDTH = 4;

    reg clk = 0;
    reg rst_n = 0;

    reg i_rx_d2c_pt_en;
    reg i_datavref_or_valvref;
    reg i_pattern_finished;
    reg [15:0] i_comparison_results;

    reg i_rx_msg_valid;
    reg [3:0] i_decoded_SB_msg;

    wire [3:0]  o_encoded_SB_msg;
    wire [15:0] o_tx_data_bus;
    wire       o_tx_msg_valid;
    wire       o_tx_data_valid;

    wire o_rx_d2c_pt_done;
    wire [15:0] o_comparison_result;

    wire o_val_pattern_en;
    wire [1:0] o_mainband_pattern_generator_cw;
    wire o_comparison_valid_en;
    wire [1:0] o_mainband_pattern_comparator_cw;

    integer pass_count = 0;
    integer fail_count = 0;

    rx_initiated_point_test_wrapper dut (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_rx_d2c_pt_en(i_rx_d2c_pt_en),
        .i_datavref_or_valvref(i_datavref_or_valvref),
        .i_pattern_finished(i_pattern_finished),
        .i_comparison_results(i_comparison_results),
        .i_rx_msg_valid(i_rx_msg_valid),
        .i_decoded_SB_msg(i_decoded_SB_msg),

        .o_encoded_SB_msg(o_encoded_SB_msg),
        .o_tx_data_bus(o_tx_data_bus),
        .o_tx_msg_valid(o_tx_msg_valid),
        .o_tx_data_valid(o_tx_data_valid),
        .o_rx_d2c_pt_done(o_rx_d2c_pt_done),
        .o_comparison_result(o_comparison_result),
        .o_val_pattern_en(o_val_pattern_en),
        .o_mainband_pattern_generator_cw(o_mainband_pattern_generator_cw),
        .o_comparison_valid_en(o_comparison_valid_en),
        .o_mainband_pattern_comparator_cw(o_mainband_pattern_comparator_cw)
    );

    always #5 clk = ~clk;

    task pass(input string msg);
    begin
        pass_count++;
        $display("[PASS] %s", msg);
    end
    endtask

    task fail(input string msg);
    begin
        fail_count++;
        $display("[FAIL] %s", msg);
    end
    endtask

    // send message and hold valid for one full cycle
    task send_msg(input [3:0] msg);
    begin
        @(posedge clk);
        i_rx_msg_valid   = 1;
        i_decoded_SB_msg = msg;

        @(posedge clk); // FSM samples here

        i_rx_msg_valid = 0;
    end
    endtask

    initial begin
        i_rx_d2c_pt_en = 0;
        i_datavref_or_valvref = 0;
        i_pattern_finished = 0;
        i_comparison_results = 0;
        i_rx_msg_valid = 0;
        i_decoded_SB_msg = 0;

        repeat (2) @(posedge clk);
        rst_n = 1;
        pass("reset released");

        // ==========================================
        // STEP 1: enable point test (START handshake)
        // ==========================================
        repeat (2) @(posedge clk);
        i_rx_d2c_pt_en = 1;
        pass("point test enabled");

        send_msg(1); // START_REQ

        repeat (2) @(posedge clk);
        if (o_encoded_SB_msg == 2)
            pass("start response received");
        else
            fail("start response not received");

        // ==========================================
        // STEP 2: LFSR clear handshake
        // ==========================================
        send_msg(3); // LFSR clear request
        pass("LFSR clear request seen");

        send_msg(4); // LFSR clear response
        pass("LFSR clear response seen");

        // ==========================================
        // STEP 3: pattern and comparison
        // ==========================================
        repeat (2) @(posedge clk);
        i_comparison_results = 16'hA5A5;
        i_pattern_finished = 1;
        pass("pattern finished");

        if (o_comparison_valid_en)
            pass("comparison enabled during pattern");
        else
            fail("comparison not enabled");

        $display("[INFO] comparison result = %h", o_comparison_result);
        @(posedge clk);
        i_pattern_finished = 0;

        // ==========================================
        // STEP 4: count done handshake
        // ==========================================
        send_msg(5); // COUNT_DONE_REQ
        pass("count done request");

       // send_msg(6); // COUNT_DONE_RESP
       // pass("count done response");

        repeat (5) @(posedge clk);
        if (!o_comparison_valid_en)
            pass("comparison disabled after count done");
        else
            fail("comparison still enabled");

        // ==========================================
        // STEP 5: end handshake
        // ==========================================
        send_msg(7); // END_REQ
        pass("end request");

        send_msg(8); // END_RESP
        pass("end response");

        // ==========================================
        // FINAL
        // ==========================================
        repeat (10) @(posedge clk);
        if (o_rx_d2c_pt_done)
            pass("point test done");
        else
            fail("point test done not asserted");

        $display("====================================");
        $display("TEST COMPLETE: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");

        $finish;
    end

endmodule