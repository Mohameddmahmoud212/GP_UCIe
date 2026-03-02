`timescale 1ns/1ps
module tb_REPAIRCLK;

    parameter CS_WIDTH = 4;
    parameter CLK_PERIOD = 10;

    // -----------------------------
    // Signals
    // -----------------------------
    logic CLK, rst_n;
    logic i_MBINIT_PARAM_end, i_CLK_Track_done;
    logic [2:0] i_Clock_track_result_logged;
    logic [3:0] i_Rx_SbMessage;
    logic i_msg_valid, i_falling_edge_busy;

    logic [3:0] o_SbMessage;
    logic o_ValidOutDatatREPAIRCLK, o_MBINIT_REPAIRCLK_Pattern_En, o_MBINIT_REPAIRCLK_end;
    logic o_train_error_req;
    logic o_clear_clk_detection;
    logic [2:0] o_Clock_track_result_logged;

    // Latch TX message when valid
    logic [3:0] tx_latched;

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
    RepairCLK_Wrapper DUT (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_MBINIT_CAL_end(i_MBINIT_PARAM_end),
        .i_CLK_Track_done(i_CLK_Track_done),
        .i_Rx_SbMessage(i_Rx_SbMessage),
        .i_msg_valid(i_msg_valid),
        .i_falling_edge_busy(i_falling_edge_busy),
        .i_Clock_track_result_logged_RXSB(i_Clock_track_result_logged),
        .i_Clock_track_result_logged_COMB(i_Clock_track_result_logged),
        .o_TX_SbMessage(o_SbMessage),
        .o_ValidOutDatatREPAIRCLK(o_ValidOutDatatREPAIRCLK),
        .o_MBINIT_REPAIRCLK_Pattern_En(o_MBINIT_REPAIRCLK_Pattern_En),
        .o_MBINIT_REPAIRCLK_end(o_MBINIT_REPAIRCLK_end),
        .o_train_error_req(o_train_error_req),
        .o_clear_clk_detection(o_clear_clk_detection),
        .o_Clock_track_result_logged(o_Clock_track_result_logged)
    );

    // -----------------------------
    // Latch TX message when valid
    // -----------------------------
    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n)
            tx_latched <= 4'b0000;
        else if(o_ValidOutDatatREPAIRCLK)
            tx_latched <= o_SbMessage;
    end

    // -----------------------------
    // Initialize inputs
    // -----------------------------
    initial begin
        i_MBINIT_PARAM_end = 0;
        i_CLK_Track_done = 0;
        i_Clock_track_result_logged = 3'b111;
        i_Rx_SbMessage = 4'b0000;
        i_msg_valid = 0;
        i_falling_edge_busy = 0;

        #(CLK_PERIOD*10);
        $display("[INFO] Starting Repair Clock test at time %0t", $time);

        i_MBINIT_PARAM_end = 1;
        run_sequence();

        $display("[INFO] Repair Clock test finished at time %0t", $time);
        $finish;
    end

    // -----------------------------
    // Automatic falling_edge_busy logic
    // -----------------------------
    always @(posedge CLK) begin
        i_falling_edge_busy <= 0;
        if(o_ValidOutDatatREPAIRCLK) i_falling_edge_busy <= 1;
    end

    // -----------------------------
    // One-shot clock pattern (non-blocking)
    // -----------------------------
    reg pattern_started;
    reg pattern_triggered;
    reg [4:0] pattern_counter;

    always @(posedge CLK or negedge rst_n) begin
        if(!rst_n) begin
            pattern_started <= 0;
            pattern_triggered <= 0;
            pattern_counter <= 0;
            i_CLK_Track_done <= 0;
        end else begin
            // trigger pattern only once per i_MBINIT_PARAM_end
            if(o_MBINIT_REPAIRCLK_Pattern_En && !pattern_triggered) begin
                pattern_started <= 1;
                pattern_triggered <= 1;
                pattern_counter <= 0;
                i_CLK_Track_done <= 0;
                $display("[INFO] Clock pattern started at %0t", $time);
            end

            // run pattern for 16 clocks
            if(pattern_started) begin
                if(pattern_counter < 16)
                    pattern_counter <= pattern_counter + 1;
                else begin
                    i_CLK_Track_done <= 1;
                    pattern_started <= 0;
                    $display("[INFO] Clock pattern done at %0t", $time);
                end
            end

            // reset trigger if i_MBINIT_PARAM_end is deasserted
            if(!i_MBINIT_PARAM_end)
                pattern_triggered <= 0;
        end
    end

    // -----------------------------
    // Automatic RX responses (multi-cycle)
    // -----------------------------
    task run_sequence;
        logic [3:0] last_tx;
        begin
            $display("[TASK] Repair Clock sequence started at %0t", $time);
            last_tx = 4'b0000;

            forever begin
                @(posedge CLK);

                // respond only on new TX
                if(tx_latched != last_tx) begin
                    last_tx = tx_latched;

                    case(tx_latched)
                        4'b0001: i_Rx_SbMessage <= 4'b0010; // INIT
                        4'b0011: i_Rx_SbMessage <= 4'b0100; // RESULT
                        4'b0101: i_Rx_SbMessage <= 4'b0110; // DONE
                        default: i_Rx_SbMessage <= 4'b0000;
                    endcase

                    if(tx_latched != 4'b0000) begin
                        // keep valid high for 3 clocks
                        i_msg_valid <= 1;
                        repeat(3) @(posedge CLK);
                        i_msg_valid <= 0;

                        $display("[INFO] RX response %b sent for %s at %0t", i_Rx_SbMessage, get_flag_name(tx_latched), $time);
                        $display("[PASS] %s detected at %0t", get_flag_name(tx_latched), $time);
                    end

                    // exit task after DONE_REQ
                    if(tx_latched == 4'b0101) begin
                        $display("[TASK] Repair Clock sequence completed at %0t", $time);
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
