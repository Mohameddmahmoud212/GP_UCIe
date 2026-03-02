`timescale 1ns/1ps
module tb_REVERSALMB;

    // -----------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------
    parameter CLK_PERIOD = 10;

    // -----------------------------------------------------------
    // Signals
    // -----------------------------------------------------------
    logic CLK, rst_n;

    // Global control
    logic i_REPAIRVAL_end;
    logic i_ltsm_in_reset;

    // Sideband RX
    logic [3:0] i_decoded_SB_msg;
    logic i_rx_msg_valid;
    logic i_falling_edge_busy;

    // Pattern / comparator
    logic i_pattern_finished;
    logic [15:0] i_REVERSAL_Result_logged_RXSB;
    logic [15:0] i_REVERSAL_Result_logged_COMB;

    // Wrapper outputs
    logic [3:0] o_encoded_SB_msg_tx;
    logic o_valid_tx;
    logic [1:0] o_mainband_pattern_generator_cw;
    logic [1:0] o_Clear_Pattern_Comparator;
    logic o_MBINIT_REVERSALMB_end;
    logic o_train_error_req_reversalmb;

    // Latch TX messages
    logic [3:0] tx_latched;

    // Pattern simulation
    logic pattern_triggered;
    integer pattern_counter;

    // Retry tracking
    integer retry_count;

    // -----------------------------------------------------------
    // Clock
    // -----------------------------------------------------------
    initial CLK = 0;
    always #(CLK_PERIOD/2) CLK = ~CLK;

    // -----------------------------------------------------------
    // Reset
    // -----------------------------------------------------------
    initial begin
        rst_n = 0; #(CLK_PERIOD*5);
        rst_n = 1;
    end

    // -----------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------
    REVERSALMB_Wrapper DUT (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_REPAIRVAL_end(i_REPAIRVAL_end),
        .i_ltsm_in_reset(i_ltsm_in_reset),
        .i_decoded_SB_msg(i_decoded_SB_msg),
        .i_rx_msg_valid(i_rx_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_pattern_finished(i_pattern_finished),
        .i_REVERSAL_Result_logged_RXSB(i_REVERSAL_Result_logged_RXSB),
        .i_REVERSAL_Result_logged_COMB(i_REVERSAL_Result_logged_COMB),
        .o_encoded_SB_msg_tx(o_encoded_SB_msg_tx),
        .o_valid_tx(o_valid_tx),
        .o_mainband_pattern_generator_cw(o_mainband_pattern_generator_cw),
        .o_Clear_Pattern_Comparator(o_Clear_Pattern_Comparator),
        .o_MBINIT_REVERSALMB_end(o_MBINIT_REVERSALMB_end),
        .o_train_error_req_reversalmb(o_train_error_req_reversalmb)
    );

    // -----------------------------------------------------------
    // Latch TX message every cycle TX valid
    // -----------------------------------------------------------
    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n)
            tx_latched <= 4'b0000;
        else if(o_valid_tx)
            tx_latched <= o_encoded_SB_msg_tx;
    end

    // -----------------------------------------------------------
    // Falling edge busy: pulse whenever TX is valid
    // -----------------------------------------------------------
    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n)
            i_falling_edge_busy <= 0;
        else
            i_falling_edge_busy <= o_valid_tx;
    end

    // -----------------------------------------------------------
    // Pattern generator: triggers every time DUT requests a pattern
    // -----------------------------------------------------------
    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n) begin
            i_pattern_finished <= 0;
            pattern_triggered <= 0;
            pattern_counter <= 0;
        end else begin
            // Trigger pattern every request
            if(o_mainband_pattern_generator_cw != 2'b00 && !pattern_triggered) begin
                pattern_triggered <= 1;
                pattern_counter <= 0;
                i_pattern_finished <= 0;
                $display("[INFO] Pattern generation started at %0t", $time);
            end

            // Simulate pattern duration: 16 cycles
            if(pattern_triggered) begin
                if(pattern_counter < 16)
                    pattern_counter <= pattern_counter + 1;
                else begin
                    i_pattern_finished <= 1;
                    pattern_triggered <= 0;
                    $display("[INFO] Pattern generation finished at %0t", $time);
                end
            end

            // Reset pattern if FSM reset
            if(i_ltsm_in_reset)
                i_pattern_finished <= 0;
        end
    end

    // -----------------------------------------------------------
    // Initialize inputs and start automated RX sequence
    // -----------------------------------------------------------
    initial begin
        i_REPAIRVAL_end = 0;
        i_ltsm_in_reset = 0;
        i_decoded_SB_msg = 4'b0000;
        i_rx_msg_valid = 0;
        i_pattern_finished = 0;
        i_REVERSAL_Result_logged_RXSB = 16'hFFFF;
        i_REVERSAL_Result_logged_COMB = 16'hFFFF;
        pattern_triggered = 0;
        pattern_counter = 0;
        retry_count = 0;

        #(CLK_PERIOD*10);
        $display("[INFO] === REVERSALMB Testbench Started ===");

        // Start the FSM
        i_REPAIRVAL_end = 1;

        // Kickstart INIT handshake
        @(posedge CLK);
        i_decoded_SB_msg <= 4'b0010; // INIT_RESP
        i_rx_msg_valid <= 1;
        @(posedge CLK); @(posedge CLK);
        i_rx_msg_valid <= 0;

        // Start RX responder task in parallel
        fork
            automatic_rx_responder();
        join_none
    end

    // -----------------------------------------------------------
    // Fully reactive RX responder task
    // -----------------------------------------------------------
    task automatic_rx_responder;
        begin
            forever @(posedge CLK) begin
                // Respond whenever TX valid is high
                if(o_valid_tx) begin
                    case(o_encoded_SB_msg_tx)
                        4'b0001: i_decoded_SB_msg <= 4'b0010; // INIT_REQ → INIT_RESP
                        4'b0011: begin
                            i_decoded_SB_msg <= 4'b0100; // CLEAR_ERROR_REQ → CLEAR_ERROR_RESP
                            retry_count = retry_count + 1;
                            $display("[INFO] Retry #%0d for CLEAR_ERROR_REQ at %0t", retry_count, $time);
                        end
                        4'b0101: i_decoded_SB_msg <= 4'b0110; // RESULT_REQ → RESULT_RESP
                        4'b0111: i_decoded_SB_msg <= 4'b1000; // DONE_REQ → DONE_RESP
                        default: i_decoded_SB_msg <= 4'b0000;
                    endcase

                    // Apply RX valid for 3 cycles
                    i_rx_msg_valid <= 1;
                    repeat(3) @(posedge CLK);
                    i_rx_msg_valid <= 0;

                    // Log
                    $display("# Time=%0t | TX=%b | Valid=%0b | PatternCW=%b | ClearComp=%b | Done=%0b | TrainErr=%0b",
                             $time, o_encoded_SB_msg_tx, o_valid_tx, o_mainband_pattern_generator_cw,
                             o_Clear_Pattern_Comparator, o_MBINIT_REVERSALMB_end, o_train_error_req_reversalmb);
                end

                // Exit condition: DUT signals done
                if(o_MBINIT_REVERSALMB_end) begin
                    $display("[INFO] === REVERSALMB Testbench Completed at %0t ===", $time);
                    $finish;
                end
            end
        end
    endtask

endmodule
