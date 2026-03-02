`timescale 1ns/1ps
module TB_RX_SBINIT;

  //parameters
  localparam SB_MSG_WIDTH = 4;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_done_req_msg       = 1;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_done_resp_msg      = 2;

   //enum to debug states in wave
   typedef enum{   IDLE_state,WAIT_FOR_DONE_REQ_state,SBINIT_DONE_RESP_state,SBINIT_END_state,ERROR_state } states_enum;

   string CS_tb, NS_tb;

    reg	i_clk;
    reg i_rst_n;
	reg	i_SBINIT_en ;
	reg i_rx_msg_valid ;
	reg i_sb_busy ;
	reg i_tx_ready_rx ;
	reg	 [SB_MSG_WIDTH-1:0] i_decoded_SB_msg ;
	wire [SB_MSG_WIDTH-1:0]o_encoded_SB_msg_rx ; 
	wire o_SBINIT_end_rx; 		
	wire o_valid_rx ;

    RX_SBINIT #(.SB_MSG_WIDTH(SB_MSG_WIDTH)) dut (
    .i_clk                (i_clk),
    .i_rst_n              (i_rst_n),
    .i_SBINIT_en          (i_SBINIT_en),
    .i_rx_msg_valid       (i_rx_msg_valid),
    .i_sb_busy            (i_sb_busy),
    .i_tx_ready_rx        (i_tx_ready_rx),
    .i_decoded_SB_msg     (i_decoded_SB_msg),
    .o_encoded_SB_msg_rx  (o_encoded_SB_msg_rx),
    .o_SBINIT_end_rx      (o_SBINIT_end_rx),
    .o_valid_rx           (o_valid_rx)
  );

  // Clock
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end

 //to easily debug states
 always@(*)begin
    case(dut.CS) 

        0:CS_tb="IDLE_state";
        1:CS_tb="WAIT_FOR_DONE_REQ_state";
        2:CS_tb="SBINIT_DONE_RESP_state";
        3:CS_tb="SBINIT_END_state";
        4:CS_tb="ERROR_state";
    endcase
 end


 always@(*)begin
    case(dut.NS) 
        0:NS_tb="IDLE_state";
        1:NS_tb="WAIT_FOR_DONE_REQ_state";
        2:NS_tb="SBINIT_DONE_RESP_state";
        3:NS_tb="SBINIT_END_state";
        4:NS_tb="ERROR_state";
    endcase
 end

//RESET TASK

task reset_dut;
    begin
        i_rst_n = 0;
        #10;
        i_rst_n = 1;
    end
endtask



task ACCEPT_TX;
begin
    while(o_valid_rx == 0) @(posedge i_clk);
    i_tx_ready_rx = 1;
    @(posedge i_clk);
    i_tx_ready_rx = 0;
end
endtask

task normal_case;
  begin
    i_SBINIT_en = 1;
    @(posedge i_clk);
    $strobe("t=%0t expected WAIT_FOR_DONE_REQ, got %s", $time, CS_tb);

    // partner sends DONE_REQ (1-cycle pulse)
    i_sb_busy        = 0;
    i_decoded_SB_msg = SBINIT_done_req_msg;
    i_rx_msg_valid   = 1;
    @(posedge i_clk);
    i_rx_msg_valid   = 0;
    i_decoded_SB_msg = 0;

    @(posedge i_clk);
    $strobe("t=%0t expected SBINIT_DONE_RESP, got %s", $time, CS_tb);

    // accept the response (handshake)
    ACCEPT_TX();

    @(posedge i_clk);
    $strobe("t=%0t expected SBINIT_END, got %s", $time, CS_tb);
    @(posedge i_clk);
  end
endtask

initial begin
    i_rst_n = 1;
    i_SBINIT_en = 0;
    i_decoded_SB_msg = 0;
    i_sb_busy = 1;           
    i_rx_msg_valid = 0;
    i_tx_ready_rx = 0;

    reset_dut();
    normal_case();
    $stop;
end

endmodule
