`timescale 1ns/1ps

module repair_tb;

    // clock/reset
    reg clk;
    reg rst_n;

    // DUT inputs
    reg        i_en;

    reg [3:0]  i_decoded_sideband_message;
    reg        i_sideband_valid;

    reg        i_busy_negedge_detected;
    reg [2:0]  i_sideband_data_lanes_encoding ;
    reg        i_first_8_lanes_are_functional ;
    reg        i_second_8_lanes_are_functional ;
    
    // DUT outputs
    wire [3:0]  o_sideband_message;
    wire        o_valid;
    
    wire [2:0]  o_sideband_data_lanes_encoding ;
    wire        o_remote_partner_first_8_lanes_result ;
    wire        o_remote_partner_second_8_lanes_result ;
    
     // Clock generation: 100MHz
    
    localparam [3:0] START_REQ = 4'b0001;
    localparam [3:0] START_RSP = 4'b0010;
    localparam [3:0] END_REQ   = 4'b0011;
    localparam [3:0] END_RSP   = 4'b0100;

    initial clk = 1'b0;
    always #5 clk = ~clk;
    // Instantiate DUT
    repair_wrapper dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_sideband_message(i_decoded_sideband_message),
        .i_sideband_valid(i_sideband_valid),
        .i_falling_edge_busy(i_busy_negedge_detected),
        .i_sideband_data_lanes_encoding(i_sideband_data_lanes_encoding),
        .i_first_8_lanes_are_functional(i_first_8_lanes_are_functional),
        .i_second_8_lanes_are_functional(i_second_8_lanes_are_functional),
        .o_sideband_message(o_sideband_message),
        .o_valid(o_valid),
        .o_sideband_data_lanes_encoding(o_sideband_data_lanes_encoding),
        .o_remote_partner_first_8_lanes_result(o_remote_partner_first_8_lanes_result),
        .o_remote_partner_second_8_lanes_result(o_remote_partner_second_8_lanes_result),
        
        .o_test_ack(o_valvref_ack)
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
        // Defaults
        rst_n = 1'b0;
        i_en  = 1'b0;

        i_decoded_sideband_message = 4'b0000;
        i_sideband_valid           = 1'b0;

        i_busy_negedge_detected    = 1'b0;

        // Partner payload default
        i_sideband_data_lanes_encoding = 3'b000; // both OK (per your REPAIR decode style)

        // Local context: assume our die can do x16
        i_first_8_lanes_are_functional  = 1'b0;
        i_second_8_lanes_are_functional = 1'b0;

        wait_cycles(5);
        rst_n = 1'b1;
        wait_cycles(2);

        // Enable selfcal wrapper
        i_en = 1'b1;
        i_first_8_lanes_are_functional  = 1'b1;
        i_second_8_lanes_are_functional = 1'b0;
        i_sideband_data_lanes_encoding = 3'b001 ;
        wait_cycles(5);
        // -------------------------------
        // Expect wrapper TX: START_REQ
        // -------------------------------
        if (o_sideband_message !== START_REQ) begin
            $display("ERROR: Expected START_REQ (0001), got %b", o_sideband_message);
            $stop;
        end
        $display("[%0t] Wrapper TX START_REQ", $time);
        drive_decoded_msg(START_REQ);
        if (o_sideband_message !== START_RSP) begin
            $display("ERROR: Expected START_RSP (0010), got %b", o_sideband_message);
            $stop;
        end
        drive_decoded_msg(START_RSP);
        $display("[%0t] Partner RX START_RSP injected", $time);
        wait_cycles(10);
        
        wait_cycles(5);
        if (o_sideband_data_lanes_encoding !== 3'b001) begin
            $display("ERROR: Expected START_RES (3'b010), got %b", o_sideband_data_lanes_encoding);
            $stop;
        end

       
        wait_cycles(10);
        if (o_sideband_message !== END_REQ) begin
            $display("ERROR: Expected END_REQ (0011), got %b", o_sideband_message);
            $stop;
        end
        $display("[%0t] Wrapper TX END_REQ", $time);
        drive_decoded_msg(END_REQ);
        if (o_sideband_message !== END_RSP) begin
            $display("ERROR: Expected END_REQ (0011), got %b", o_sideband_message);
            $stop;
        end
        wait_cycles(2);
        drive_decoded_msg(END_RSP);

        wait_cycles(10);

        // Check ack
        if (o_valvref_ack !== 1'b1) begin
            $display("ERROR: o_valvref_ack did not assert after END_RSP.");
            $stop;
        end

        // Check remote partner decode (based on repair_rx style mapping)
        if (o_remote_partner_first_8_lanes_result !== 1'b1 ||
            o_remote_partner_second_8_lanes_result !== 1'b0) begin
            $display("ERROR: remote partner lane decode wrong. first8=%0d second8=%0d",
                     o_remote_partner_first_8_lanes_result,
                     o_remote_partner_second_8_lanes_result);
            $stop;
        end

        $display("[%0t] PASS: ack=%0d remote_first8=%0d remote_second8=%0d",
                 $time, o_valvref_ack,
                 o_remote_partner_first_8_lanes_result,
                 o_remote_partner_second_8_lanes_result);

        // Disable
        wait_cycles(5);
        i_en = 1'b0;

        wait_cycles(10);
        $display("TB PASS.");
        $stop;
    end

endmodule