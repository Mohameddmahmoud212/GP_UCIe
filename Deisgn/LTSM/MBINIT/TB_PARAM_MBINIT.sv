`timescale 1ns/1ps

module TB_PARAM_MBINIT;

    reg CLK;
    reg rst_n;

    reg i_MBINIT_Start_en;
    reg i_Busy_SideBand;

    reg [4:0] i_TX_VoltageSwing;
    reg [2:0] i_TX_MaxDataRate;
    reg       i_TX_ClockMode;
    reg       i_TX_PhaseClock;

    reg [4:0] i_RX_VoltageSwing_Cap;
    reg [2:0] i_RX_MaxDataRate_Cap;
    reg       i_RX_ClockMode_Cap;
    reg       i_RX_PhaseClock_Cap;

    wire [2:0] o_Final_MaxDataRate_TX;
    wire [2:0] o_Final_MaxDataRate_RX;
    wire       o_MBINIT_PARAM_TX_end;
    wire       o_MBINIT_PARAM_RX_end;
    wire       o_train_error_req;

    PARAM_WRAPPER dut (.*);

    always #5 CLK = ~CLK;

    task start_mbinit;
        begin
            i_MBINIT_Start_en = 1;
            @(posedge CLK);
            i_MBINIT_Start_en = 0;
        end
    endtask

    initial begin
        CLK = 0;
        rst_n = 0;
        i_MBINIT_Start_en = 0;
        i_Busy_SideBand = 0;

        #20 rst_n = 1;

        // === Test 1: Perfect Match ===
        i_TX_VoltageSwing = 5'h1A;
        i_TX_MaxDataRate  = 3'd4;
        i_TX_ClockMode    = 1;
        i_TX_PhaseClock   = 0;

        i_RX_VoltageSwing_Cap = 5'h1A;
        i_RX_MaxDataRate_Cap  = 3'd4;
        i_RX_ClockMode_Cap    = 1;
        i_RX_PhaseClock_Cap   = 0;

        start_mbinit;
        #20;

        if (!o_train_error_req)
            $display("PASS: Perfect match negotiation succeeded");
        else
            $display("FAIL");

        // === Test 2: Max Data Rate Mismatch ===
        i_TX_MaxDataRate  = 3'd6;
        i_RX_MaxDataRate_Cap = 3'd3;

        start_mbinit;
        #20;

        if (o_Final_MaxDataRate_RX == 3'd3)
            $display("PASS: Max data rate mismatch resolved");
        else
            $display("FAIL");

        // === Test 3: Parameter Mismatch ===
        i_RX_ClockMode_Cap = ~i_TX_ClockMode;

        start_mbinit;
        #20;

        if (o_train_error_req)
            $display("PASS: Train error detected");
        else
            $display("FAIL");

        $stop;
    end

endmodule
