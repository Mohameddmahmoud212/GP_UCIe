`timescale 1ns/1ps
module TB_TX_SBINIT;

  //parameters
  localparam SB_MSG_WIDTH = 4;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_done_req_msg       = 1;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_done_resp_msg      = 2;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_Out_of_Reset_msg   = 3;


   //enum to debug states in wave
   typedef enum{   IDLE_state,START_SB_PATTERN_state,SBINIT_OUT_OF_RESET_state,WAIT_SB_BUSY_state,SBINIT_done_req_state,SBINIT_END_state,ERROR_state  } states_enum;
   string CS_tb, NS_tb;

  //inputs
  reg                         i_clk;
  reg                         i_rst_n;
  reg                         i_SBINIT_en;
  reg                         i_start_pattern_done;
  reg                         i_rx_msg_valid;
  reg                         i_sb_busy;
  reg                         i_tx_ready_tx;
  reg   [SB_MSG_WIDTH-1:0]    i_decoded_SB_msg;
 
  //outputs
  wire                        o_start_pattern_req;
  wire [SB_MSG_WIDTH-1:0]     o_encoded_SB_msg_tx;
  wire                        o_SBINIT_end_tx;
  wire                        o_valid_tx;


  TX_SBINIT #(.SB_MSG_WIDTH(SB_MSG_WIDTH)) dut (
    .i_clk                (i_clk),
    .i_rst_n              (i_rst_n),
    .i_SBINIT_en          (i_SBINIT_en),
    .i_start_pattern_done (i_start_pattern_done),
    .i_rx_msg_valid       (i_rx_msg_valid),
    .i_sb_busy            (i_sb_busy),
    .i_tx_ready_tx        (i_tx_ready_tx),
    .i_decoded_SB_msg     (i_decoded_SB_msg),
    .o_encoded_SB_msg_tx  (o_encoded_SB_msg_tx),
    .o_start_pattern_req  (o_start_pattern_req),
    .o_SBINIT_end_tx      (o_SBINIT_end_tx),
    .o_valid_tx           (o_valid_tx)
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
        1:CS_tb="START_SB_PATTERN_state";
        2:CS_tb="SBINIT_OUT_OF_RESET_state";
        3:CS_tb="WAIT_SB_BUSY_state";
        4:CS_tb="SBINIT_done_req_state";
        5:CS_tb="SBINIT_END_state";
        6:CS_tb="ERROR_state";
    endcase
 end


 always@(*)begin
    case(dut.NS) 

        0:NS_tb="IDLE_state";
        1:NS_tb="START_SB_PATTERN_state";
        2:NS_tb="SBINIT_OUT_OF_RESET_state";
        3:NS_tb="WAIT_SB_BUSY_state";
        4:NS_tb="SBINIT_done_req_state";
        5:NS_tb="SBINIT_END_state";
        6:NS_tb="ERROR_state";
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

   // Deassert valid task
    task DEASSERT_VALID; 
        i_sb_busy = 0;
        #20;
        i_sb_busy = 1;
    endtask

    task ACCEPT_TX;
    begin
        while(o_valid_tx == 0) @(posedge i_clk);
        i_tx_ready_tx = 1;
        @(posedge i_clk);
        i_tx_ready_tx = 0;
    end
endtask



task normal_case;

    begin
        // enable
        i_SBINIT_en = 1;
        @(posedge i_clk);
        $strobe("time = %0t Expected Current state is->START_SB_PATTERN and it's->%s  : ",$time ,  CS_tb);

        repeat(3) @(posedge i_clk);

        // pattern done pulse
        i_start_pattern_done = 1;
        $strobe("time = %0t Pattern done pulse DONE" , $time);
        @(posedge i_clk);
        i_start_pattern_done = 0;

        $strobe("time = %0t Expected Current state is->SBINIT_OUT_OF_RESET and it's->%s : ",$time , CS_tb);
        // make SB ready
        repeat(2) @(posedge i_clk);
        i_sb_busy = 0;
        $strobe("time = %0t SB is now NOT busy (i_sb_busy=0)",$time);
        @(posedge i_clk);
        
        // accept OUT_OF_RESET from TX
        $strobe("time = %0t Waiting TX to assert valid for OUT_OF_RESET" , $time);
        ACCEPT_TX();
        $strobe("time = %0t Accepted TX message, o_encoded_SB_msg_tx=%0d" ,$time, o_encoded_SB_msg_tx);

        // partner sends OUT_OF_RESET (1-cycle pulse)
        repeat(2) @(posedge i_clk);
        i_decoded_SB_msg = SBINIT_Out_of_Reset_msg;
        i_rx_msg_valid   = 1;
        $strobe("time = %0t, Partner sends OUT_OF_RESET msg=%0d", $time,i_decoded_SB_msg);
        @(posedge i_clk);
        i_rx_msg_valid   = 0;
        i_decoded_SB_msg = 0;

        $strobe("time = %0t Expected Current state is->WAIT_FOR_SB_BUSY and it's->%s : ",$time, CS_tb);
        //in wait for sb busy the i_busy is already 0 so its not busy and will go to sbinit done req
        @(posedge i_clk);
      

        $strobe("time = %0t Expected Current state is->SBINIT_DONE_REQ and it's->%s : ",$time,CS_tb);

        // accept DONE_REQ from TX
        $strobe("time = %0t Waiting TX to assert valid for DONE_REQ...",$time);
        ACCEPT_TX();
        $strobe("time = %0t Accepted TX message, o_encoded_SB_msg_tx=%0d",$time, o_encoded_SB_msg_tx);

        // partner sends DONE_RESP (1-cycle pulse)
        repeat(2) @(posedge i_clk);
        i_decoded_SB_msg = SBINIT_done_resp_msg;
        i_rx_msg_valid   = 1;
        $display("time = %0t Partner sends DONE_RESP msg=%0d",$time, i_decoded_SB_msg);
        @(posedge i_clk);
        i_rx_msg_valid   = 0;
        i_decoded_SB_msg = 0;
        $strobe("time = %0t Expected Current state is->SBINIT_END and it's->%s : ",$time, CS_tb);

        repeat(5) @(posedge i_clk);

        i_SBINIT_en = 0;
        $strobe("time = %0t SBINIT_en disabled, returning to IDLE",$time);
        @(posedge i_clk);
        $strobe("time = %0t Expected Current state is->IDLE and it's->%s : ",$time, CS_tb);
        @(posedge i_clk);
    end
endtask


initial begin
    i_rst_n = 1;
    i_SBINIT_en = 0;
    i_start_pattern_done = 0;
    i_decoded_SB_msg = 0;
    i_sb_busy = 1;           
    i_rx_msg_valid = 0;
    i_tx_ready_tx = 0;

    reset_dut();
    normal_case();
    $stop;
end

endmodule
