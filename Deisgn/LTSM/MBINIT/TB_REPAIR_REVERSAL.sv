`timescale 1ns/1ps

module TB_REPAIR_REVERSAL;

    // Clock and reset
    reg CLK;
    reg rst_n;

    // Inputs
    reg i_REPAIRVAL_end;
    reg i_REVERSAL_done;
    reg i_LaneID_Pattern_done;
    reg i_falling_edge_busy;
    reg [3:0] i_Rx_SbMessage;
    reg i_msg_valid;
    reg [15:0] i_REVERSAL_Result_logged_RXSB;
    reg [15:0] i_REVERSAL_Result_logged_COMB;

    // Outputs
    wire [1:0] o_MBINIT_REVERSALMB_LaneID_Pattern_En;
    wire o_MBINIT_REVERSALMB_ApplyReversal_En;
    wire o_MBINIT_REVERSALMB_end;
    wire [3:0] o_TX_SbMessage;
    wire [1:0] o_Clear_Pattern_Comparator;
    wire [15:0] o_REVERSAL_Pattern_Result_logged;
    wire o_ValidOutDatatREVERSALMB;
    wire o_ValidDataFieldParameters;
    wire o_train_error_req_reversalmb;

    // Instantiate wrapper
    REVERSALMB_Wrapper uut (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_REPAIRVAL_end(i_REPAIRVAL_end),
        .i_REVERSAL_done(i_REVERSAL_done),
        .i_LaneID_Pattern_done(i_LaneID_Pattern_done),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_Rx_SbMessage(i_Rx_SbMessage),
        .i_msg_valid(i_msg_valid),
        .i_REVERSAL_Result_logged_RXSB(i_REVERSAL_Result_logged_RXSB),
        .i_REVERSAL_Result_logged_COMB(i_REVERSAL_Result_logged_COMB),

        .o_MBINIT_REVERSALMB_LaneID_Pattern_En(o_MBINIT_REVERSALMB_LaneID_Pattern_En),
        .o_MBINIT_REVERSALMB_ApplyReversal_En(o_MBINIT_REVERSALMB_ApplyReversal_En),
        .o_MBINIT_REVERSALMB_end(o_MBINIT_REVERSALMB_end),
        .o_TX_SbMessage(o_TX_SbMessage),
        .o_Clear_Pattern_Comparator(o_Clear_Pattern_Comparator),
        .o_REVERSAL_Pattern_Result_logged(o_REVERSAL_Pattern_Result_logged),
        .o_ValidOutDatatREVERSALMB(o_ValidOutDatatREVERSALMB),
        .o_ValidDataFieldParameters(o_ValidDataFieldParameters),
        .o_train_error_req_reversalmb(o_train_error_req_reversalmb)
    );

    // Clock generation
    initial CLK = 0;
    always #5 CLK = ~CLK; // 100 MHz clock

    // Test sequence
    initial begin
        // Reset
        rst_n = 0;
        i_REPAIRVAL_end = 0;
        i_REVERSAL_done = 0;
        i_LaneID_Pattern_done = 0;
        i_falling_edge_busy = 0;
        i_Rx_SbMessage = 0;
        i_msg_valid = 0;
        i_REVERSAL_Result_logged_RXSB = 16'h0000;
        i_REVERSAL_Result_logged_COMB = 16'h0000;
        #20;
        rst_n = 1;

        // Start test
        repeat (2) @(posedge CLK); 
        start_reversal_sequence();
        wait_for_reversal_end();

        $display("\n[SIMULATION DONE] All sequences finished successfully.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Task to start the REVERSAL sequence
    // -------------------------------------------------------------------------
    task start_reversal_sequence;
    begin
        i_REPAIRVAL_end = 1;
        i_LaneID_Pattern_done = 1;
        i_REVERSAL_done = 0;
        i_msg_valid = 1;
        i_Rx_SbMessage = 4'b0010;
        i_REVERSAL_Result_logged_RXSB = 16'hAAAA;
        i_REVERSAL_Result_logged_COMB = 16'h5555;

        repeat (5) @(posedge CLK); // Hold signals for a few cycles
        i_REPAIRVAL_end = 0;
        i_LaneID_Pattern_done = 0;
        i_msg_valid = 0;

        // Simulate REVERSAL done after some time
        #100 i_REVERSAL_done = 1;
        #10 i_REVERSAL_done = 0;
    end
    endtask

    // -------------------------------------------------------------------------
    // Task to wait for o_MBINIT_REVERSALMB_end
    // -------------------------------------------------------------------------
    task wait_for_reversal_end;
    integer timeout;
    begin
        timeout = 0;
        while (!o_MBINIT_REVERSALMB_end && timeout < 5000) begin
            @(posedge CLK);
            timeout = timeout + 1;
            print_signals();
        end
        if (!o_MBINIT_REVERSALMB_end)
            $fatal("[ERROR] TIMEOUT: REVERSAL DID NOT END");
        else
            $display("[INFO] REVERSAL sequence completed at time %0t", $time);
    end
    endtask

    // -------------------------------------------------------------------------
    // Task to print signals every cycle
    // -------------------------------------------------------------------------
    task print_signals;
    begin
        $display("T=%0t | TX=%b | LaneIDEn=%b | ApplyRev=%b | End=%b | Valid=%b",
            $time,
            o_TX_SbMessage,
            o_MBINIT_REVERSALMB_LaneID_Pattern_En,
            o_MBINIT_REVERSALMB_ApplyReversal_En,
            o_MBINIT_REVERSALMB_end,
            o_ValidOutDatatREVERSALMB
        );
    end
    endtask

endmodule
