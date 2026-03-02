`timescale 1ns/1ps

module TB_TRAINERROR_HS_WRAPPER;

//////////////////////////////////////////////////
//////////////// PARAMETERS ////////////////////
//////////////////////////////////////////////////

localparam SB_MSG_WIDTH = 4;

localparam TRAINERROR_REQ  = 4'd15;
localparam TRAINERROR_RESP = 4'd14;

//////////////////////////////////////////////////
//////////////// DUT SIGNALS ////////////////////
//////////////////////////////////////////////////

reg                    i_clk;
reg                    i_rst_n;
reg                    i_trainerror_en;
reg                    i_rx_msg_valid;
reg [SB_MSG_WIDTH-1:0]  i_decoded_SB_msg;

wire [SB_MSG_WIDTH-1:0] o_encoded_SB_msg;
wire                   o_TRAINERROR_HS_end;
wire                   o_tx_msg_valid;

integer error_count = 0;

//////////////////////////////////////////////////
//////////////// EDGE DETECTION //////////////////
//////////////////////////////////////////////////

reg end_seen; // captures any pulse of handshake end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        end_seen <= 0;
    else if (o_TRAINERROR_HS_end)
        end_seen <= 1;
end

//////////////////////////////////////////////////
//////////////// INSTANTIATE DUT ////////////////
//////////////////////////////////////////////////

TRAINERROR_HS_WRAPPER #(
    .SB_MSG_WIDTH(SB_MSG_WIDTH)
) dut (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),
    .i_trainerror_en        (i_trainerror_en),
    .i_rx_msg_valid         (i_rx_msg_valid),
    .i_decoded_SB_msg       (i_decoded_SB_msg),
    .o_encoded_SB_msg        (o_encoded_SB_msg),
    .o_TRAINERROR_HS_end      (o_TRAINERROR_HS_end),
    .o_tx_msg_valid           (o_tx_msg_valid)
);

//////////////////////////////////////////////////
//////////////// CLOCK //////////////////////////
//////////////////////////////////////////////////

initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
end

//////////////////////////////////////////////////
//////////////// BASIC TASKS ////////////////////
//////////////////////////////////////////////////

task DELAY(input integer cycles);
begin
    repeat(cycles) @(posedge i_clk);
end
endtask

task RESET_DUT;
begin
    $display("=== RESET ===");
    i_rst_n = 0;
    DELAY(4);
    i_rst_n = 1;
    DELAY(4);
end
endtask

// partner message pulse
task PARTNER_SEND(input [3:0] msg);
begin
    @(posedge i_clk);
    i_decoded_SB_msg = msg;
    i_rx_msg_valid   = 1;
    $display("[PARTNER] send msg=%0d", msg);

    @(posedge i_clk);
    i_rx_msg_valid  = 0;
    i_decoded_SB_msg = 0;
    $display("[PARTNER] pulse end");
end
endtask

//////////////////////////////////////////////////
//////////////// DEBUG REPORT ///////////////////
//////////////////////////////////////////////////

task debug_report(input string tag);
begin
    $display("--- DEBUG: %s ---", tag);
    $display("i_trainerror_en = %b", i_trainerror_en);
    $display("i_rx_msg_valid  = %b", i_rx_msg_valid);
    $display("o_tx_msg_valid  = %b", o_tx_msg_valid);
    $display("o_end           = %b", o_TRAINERROR_HS_end);
    $display("end_seen        = %b", end_seen);
end
endtask

//////////////////////////////////////////////////
//////////////// CHECK HANDSHAKE /////////////////
//////////////////////////////////////////////////

task CHECK_HANDSHAKE(input string name);
begin
    DELAY(5);

    if (end_seen)
        $display(" PASS: %s handshake completed", name);
    else begin
        $display(" FAIL: %s handshake NOT completed", name);
        error_count++;
    end

    debug_report(name);
    end_seen = 0; // reset for next test
end
endtask

//////////////////////////////////////////////////
//////////////// TESTS //////////////////////////
//////////////////////////////////////////////////

task TEST_CASE_NORMAL;
begin
    $display("\n===== TEST_CASE_NORMAL =====");

    i_trainerror_en = 1;
    DELAY(4); // allow TX to send REQ

    PARTNER_SEND(TRAINERROR_RESP);
    DELAY(6);

    CHECK_HANDSHAKE("TEST_CASE_NORMAL");

    i_trainerror_en = 0;
    DELAY(5);
end
endtask

task TEST_CASE_PARTNER_FIRST;
begin
    $display("\n===== TEST_CASE_PARTNER_FIRST =====");

    i_trainerror_en = 1;

    PARTNER_SEND(TRAINERROR_REQ);
    DELAY(4);

    PARTNER_SEND(TRAINERROR_RESP);
    DELAY(6);

    CHECK_HANDSHAKE("TEST_CASE_PARTNER_FIRST");

    i_trainerror_en = 0;
    DELAY(5);
end
endtask

task TEST_CASE_DELAYED_RESP;
begin
    $display("\n===== TEST_CASE_DELAYED_RESP =====");

    i_trainerror_en = 1;
    DELAY(4);

    // long wait before response
    DELAY(10);

    PARTNER_SEND(TRAINERROR_RESP);
    DELAY(8);

    CHECK_HANDSHAKE("TEST_CASE_DELAYED_RESP");

    i_trainerror_en = 0;
    DELAY(5);
end
endtask

//////////////////////////////////////////////////
//////////////// MAIN ///////////////////////////
//////////////////////////////////////////////////

initial begin
    i_rst_n          = 1;
    i_trainerror_en  = 0;
    i_rx_msg_valid    = 0;
    i_decoded_SB_msg  = 0;
    end_seen         = 0;

    RESET_DUT();

    TEST_CASE_NORMAL();
    TEST_CASE_PARTNER_FIRST();
    TEST_CASE_DELAYED_RESP();

    if (error_count == 0)
        $display("\n🎉 ALL TESTS PASSED SUCCESSFULLY 🎉");
    else
        $display("\n🚨 SIMULATION FAILED with %0d errors 🚨", error_count);

    #20;
    $stop;
end

endmodule