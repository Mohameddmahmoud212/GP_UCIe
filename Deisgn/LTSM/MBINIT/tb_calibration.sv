`timescale 1ns/1ps
module CAL_TOP_WRAPPER_tb;

parameter SB_MSG_WIDTH = 4;
localparam CLK_PERIOD = 10;

reg  CLK;
reg  rst_n;
reg  i_MBINIT_PARAM_end;
reg  i_Busy_SideBand;
reg  i_falling_edge_busy;
reg  [SB_MSG_WIDTH-1:0] i_RX_SbMessage;
reg  i_msg_valid;

wire [SB_MSG_WIDTH-1:0] o_TX_SbMessage;
wire o_ValidOutDatat;
wire o_MBINIT_CAL_end;
wire [1:0] CS_TX_OUT;
wire [1:0] CS_RX_OUT;

integer errors;

CAL_TOP_WRAPPER #(.SB_MSG_WIDTH(SB_MSG_WIDTH)) dut (
    .CLK(CLK),
    .rst_n(rst_n),
    .i_MBINIT_PARAM_end(i_MBINIT_PARAM_end),
    .i_Busy_SideBand(i_Busy_SideBand),
    .i_falling_edge_busy(i_falling_edge_busy),
    .i_RX_SbMessage(i_RX_SbMessage),
    .i_msg_valid(i_msg_valid),
    .o_TX_SbMessage(o_TX_SbMessage),
    .o_ValidOutDatat(o_ValidOutDatat),
    .o_MBINIT_CAL_end(o_MBINIT_CAL_end),
    .CS_TX_OUT(CS_TX_OUT),
    .CS_RX_OUT(CS_RX_OUT)
);

// Clock
initial CLK = 0;
always #(CLK_PERIOD/2) CLK = ~CLK;

// Reset
task reset_dut;
begin
    rst_n = 0;
    i_MBINIT_PARAM_end = 0;
    i_Busy_SideBand = 0;
    i_falling_edge_busy = 0;
    i_RX_SbMessage = 0;
    i_msg_valid = 0;
    #(2*CLK_PERIOD);
    rst_n = 1;
    #(2*CLK_PERIOD);
end
endtask

task busy_falling_edge;
begin
    i_falling_edge_busy = 1;
    @(posedge CLK);
    i_falling_edge_busy = 0;
end
endtask

task send_rx_msg(input [SB_MSG_WIDTH-1:0] msg);
begin
    i_RX_SbMessage = msg;
    i_msg_valid = 1;
    @(posedge CLK);
    i_msg_valid = 0;
end
endtask

task check_tx_msg(input [SB_MSG_WIDTH-1:0] expected);
begin
    if (o_TX_SbMessage !== expected || o_ValidOutDatat !== 1) begin
        $display("ERROR: Expected TX message %b, got %b at time %0t",
                 expected, o_TX_SbMessage, $time);
        errors = errors + 1;
    end else begin
        $display("INFO: Correct TX message %b at time %0t", expected, $time);
    end
end
endtask

// FSM logging
always @(posedge CLK) begin
    $display("Time: %0t | TX_CS: %0d | RX_CS: %0d | TX_msg: %b | MBINIT_CAL_end: %b",
             $time, CS_TX_OUT, CS_RX_OUT, o_TX_SbMessage, o_MBINIT_CAL_end);
end

// Main test sequence
initial begin
    errors = 0;
    reset_dut();

    // Step 1: Enable MBINIT
    i_MBINIT_PARAM_end = 1;

    // Wait until TX FSM enters MBINIT_CAL_REQ
    wait(CS_TX_OUT == 2'b01);
    @(posedge CLK);

    // Step 2: TX sends request
    check_tx_msg(4'b0001);
    busy_falling_edge();

    // Step 3: Simulate RX sees request
    send_rx_msg(4'b0001);

    // Wait until TX FSM enters MBINIT_HANDLE_VALID
    wait(CS_TX_OUT == 2'b10);
    @(posedge CLK);
    check_tx_msg(4'b0010);

    // Step 4: Wait for CAL completion
    wait(o_MBINIT_CAL_end == 1);
    @(posedge CLK);

    // Step 5: Deassert MBINIT
    i_MBINIT_PARAM_end = 0;
    @(posedge CLK);
    @(posedge CLK);

    if (o_MBINIT_CAL_end !== 0) begin
        $display("ERROR: CAL end did not reset after MBINIT deassertion!");
        errors = errors + 1;
    end else $display("INFO: CAL end correctly reset after MBINIT deassertion.");

    if (errors == 0) $display("TEST PASSED: All checks successful.");
    else $display("TEST FAILED: %0d errors detected.", errors);

    $stop;
end

endmodule
