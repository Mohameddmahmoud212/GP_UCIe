`timescale 1ns/1ps
module tb_REPAIRVAL;

    parameter CLK_PERIOD = 10;

    // -----------------------------
    // Signals
    // -----------------------------
    logic CLK, rst_n;
    logic i_REPAIRCLK_end, i_VAL_Pattern_done;
    logic i_VAL_Result_logged_RXSB, i_VAL_Result_logged_COMB;
    logic [3:0] i_Rx_SbMessage;
    logic i_msg_valid, i_falling_edge_busy;

    logic [3:0] o_TX_SbMessage;
    logic o_ValidOutDatatREPAIRVAL, o_MBINIT_REPAIRVAL_Pattern_En, o_MBINIT_REPAIRVAL_end;
    logic o_train_error_req, o_VAL_Result_logged, o_enable_cons;

    // latch TX message when valid
    logic [3:0] tx_latched;

    // scoreboard counters
    integer pass_count = 0;
    integer fail_count = 0;

    // -----------------------------
    // Clock
    // -----------------------------
    initial CLK = 0;
    always #(CLK_PERIOD/2) CLK = ~CLK;

    // -----------------------------
    // Reset
    // -----------------------------
    initial begin
        rst_n = 0; #(CLK_PERIOD*5);
        rst_n = 1;
    end

    // -----------------------------
    // DUT instantiation
    // -----------------------------
    REPAIRVAL_Wrapper DUT (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_REPAIRCLK_end(i_REPAIRCLK_end),
        .i_VAL_Pattern_done(i_VAL_Pattern_done),
        .i_Rx_SbMessage(i_Rx_SbMessage),
        .i_msg_valid(i_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_VAL_Result_logged_RXSB(i_VAL_Result_logged_RXSB),
        .i_VAL_Result_logged_COMB(i_VAL_Result_logged_COMB),
        .o_TX_SbMessage(o_TX_SbMessage),
        .o_ValidOutDatatREPAIRVAL(o_ValidOutDatatREPAIRVAL),
        .o_MBINIT_REPAIRVAL_Pattern_En(o_MBINIT_REPAIRVAL_Pattern_En),
        .o_MBINIT_REPAIRVAL_end(o_MBINIT_REPAIRVAL_end),
        .o_train_error_req(o_train_error_req),
        .o_VAL_Result_logged(o_VAL_Result_logged),
        .o_enable_cons(o_enable_cons)
    );

    // -----------------------------
    // Latch TX message when valid
    // -----------------------------
    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n)
            tx_latched <= 4'b0000;
        else if(o_ValidOutDatatREPAIRVAL)
            tx_latched <= o_TX_SbMessage;
    end

    // -----------------------------
    // Initialize inputs
    // -----------------------------
    initial begin
        i_REPAIRCLK_end = 0;
        i_VAL_Pattern_done = 0;
        i_VAL_Result_logged_RXSB = 1;
        i_VAL_Result_logged_COMB = 1;
        i_Rx_SbMessage = 4'b0000;
        i_msg_valid = 0;
        i_falling_edge_busy = 0;

        #(CLK_PERIOD*10);
        $display("[INFO] Starting Repair VAL test at time %0t", $time);

        // enable REPAIRVAL phase
        i_REPAIRCLK_end = 1;

        run_sequence();

        // scoreboard report
        $display("========================================");
        $display("[SUMMARY] Total PASS = %0d", pass_count);
        $display("[SUMMARY] Total FAIL = %0d", fail_count);
        $display("========================================");

        $display("[INFO] Repair VAL test finished at time %0t", $time);
        $finish;
    end

    // -----------------------------
    // Automatic falling_edge_busy logic
    // -----------------------------
    always @(posedge CLK) begin
        i_falling_edge_busy <= 0;
        if(o_ValidOutDatatREPAIRVAL) i_falling_edge_busy <= 1;
    end

    // -----------------------------
    // Automatic VAL pattern completion
    // -----------------------------
    reg pattern_started;
    reg pattern_triggered;
    reg [4:0] pattern_counter;

    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n) begin
            pattern_started <= 0;
            pattern_triggered <= 0;
            pattern_counter <= 0;
            i_VAL_Pattern_done <= 0;
        end else begin
            if(o_MBINIT_REPAIRVAL_Pattern_En && !pattern_triggered) begin
                pattern_started <= 1;
                pattern_triggered <= 1;
                pattern_counter <= 0;
                i_VAL_Pattern_done <= 0;
                $display("[INFO] VAL pattern started at %0t", $time);
            end

            if(pattern_started) begin
                if(pattern_counter < 16)
                    pattern_counter <= pattern_counter + 1;
                else begin
                    i_VAL_Pattern_done <= 1;
                    pattern_started <= 0;
                    $display("[INFO] VAL pattern done at %0t", $time);
                end
            end

            if(!i_REPAIRCLK_end)
                pattern_triggered <= 0;
        end
    end

    // -----------------------------
    // Automatic RX responses with random failures
    // -----------------------------
    task run_sequence;
        logic [3:0] last_tx;
        begin
            $display("[TASK] Repair VAL sequence started at %0t", $time);
            last_tx = 4'b0000;

            forever begin
                @(posedge CLK);

                if(tx_latched != last_tx) begin
                    last_tx = tx_latched;

                    // inject random failure during RESULT_REQ (50% chance)
                    if(tx_latched == 4'b0011) begin
                        i_VAL_Result_logged_COMB = ($urandom_range(0,1)) ? 1 : 0;
                        if(!i_VAL_Result_logged_COMB)
                            $display("[INFO] Injected simulated failure at %0t", $time);
                    end

                    case(tx_latched)
                        4'b0001: i_Rx_SbMessage <= 4'b0010; // INIT_RESP
                        4'b0011: i_Rx_SbMessage <= 4'b0100; // RESULT_RESP
                        4'b0101: i_Rx_SbMessage <= 4'b0110; // DONE_RESP
                        default: i_Rx_SbMessage <= 4'b0000;
                    endcase

                    if(tx_latched != 4'b0000) begin
                        i_msg_valid <= 1;
                        repeat(3) @(posedge CLK);
                        i_msg_valid <= 0;

                        // check for errors
                        if(tx_latched == 4'b0011 && !i_VAL_Result_logged_COMB) begin
                            $display("[FAIL] RESULT_RESP indicates failure at %0t", $time);
                            fail_count++;
                        end else begin
                            $display("[PASS] %s detected at %0t", get_flag_name(tx_latched), $time);
                            if(tx_latched == 4'b0011) pass_count++;
                        end
                    end

                    // exit after DONE_REQ
                    if(tx_latched == 4'b0101) begin
                        $display("[TASK] Repair VAL sequence completed at %0t", $time);
                        disable run_sequence;
                    end
                end
            end
        end
    endtask

    // -----------------------------
    // Function to get string for logging
    // -----------------------------
    function string get_flag_name(input [3:0] msg);
        case(msg)
            4'b0001: get_flag_name = "INIT_REQ";
            4'b0011: get_flag_name = "RESULT_REQ";
            4'b0101: get_flag_name = "DONE_REQ";
            default: get_flag_name = "UNKNOWN_REQ";
        endcase
    endfunction

endmodule
