`timescale 1ns/1ps
module TB_SBINIT_WRAPPER;

  localparam SB_MSG_WIDTH = 4;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_done_req_msg     = 1;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_done_resp_msg    = 2;
  localparam [SB_MSG_WIDTH-1:0] SBINIT_Out_of_Reset_msg = 3;

  // =========================
  // TB signals
  // =========================
  reg                       i_clk;
  reg                       i_rst_n;
  reg                       i_SBINIT_en;

  reg                       i_start_pattern_done;
  reg                       i_rx_msg_valid;
  reg                       i_sb_busy;
  reg  [SB_MSG_WIDTH-1:0]   i_decoded_SB_msg;

  wire [SB_MSG_WIDTH-1:0]   o_encoded_SB_msg;
  wire                      o_tx_msg_valid;
  wire                      o_start_pattern_req;
  wire                      o_SBINIT_end;

  // =========================
  // DUT
  // =========================
  SBINIT_WRAPPER #(.SB_MSG_WIDTH(SB_MSG_WIDTH)) dut (
    .i_clk               (i_clk),
    .i_rst_n             (i_rst_n),
    .i_SBINIT_en         (i_SBINIT_en),
    .i_start_pattern_done(i_start_pattern_done),
    .i_rx_msg_valid      (i_rx_msg_valid),
    .i_sb_busy           (i_sb_busy),
    .i_decoded_SB_msg    (i_decoded_SB_msg),
    .o_encoded_SB_msg    (o_encoded_SB_msg),
    .o_tx_msg_valid      (o_tx_msg_valid),
    .o_start_pattern_req (o_start_pattern_req),
    .o_SBINIT_end        (o_SBINIT_end)
  );

  //enum to debug states in wave
   typedef enum{   IDLE_state_TX,START_SB_PATTERN_state_TX,SBINIT_OUT_OF_RESET_state_TX,WAIT_SB_BUSY_state_TX,SBINIT_done_req_state_TX,SBINIT_END_state_TX,ERROR_state_TX  } states_enum_TX;
   typedef enum{   IDLE_state_RX,WAIT_FOR_DONE_REQ_state_RX,SBINIT_DONE_RESP_state_RX,SBINIT_END_state_RX,ERROR_state_RX } states_enum_RX;

   string CS_tb_wp_tx,CS_tb_wp_rx;

  // =========================
  // Clock
  // =========================
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end

//to easily debug states
 always@(*)begin
    case(dut.U_TX_SBINIT.CS) 

        0:CS_tb_wp_tx="IDLE_state";
        1:CS_tb_wp_tx="START_SB_PATTERN_state";
        2:CS_tb_wp_tx="SBINIT_OUT_OF_RESET_state";
        3:CS_tb_wp_tx="WAIT_SB_BUSY_state";
        4:CS_tb_wp_tx="SBINIT_done_req_state";
        5:CS_tb_wp_tx="SBINIT_END_state";
        6:CS_tb_wp_tx="ERROR_state";
    endcase
 end

 //to easily debug states
 always@(*)begin
    case(dut.U_RX_SBINIT.CS) 

        0:CS_tb_wp_rx="IDLE_state";
        1:CS_tb_wp_rx="WAIT_FOR_DONE_REQ_state";
        2:CS_tb_wp_rx="SBINIT_DONE_RESP_state";
        3:CS_tb_wp_rx="SBINIT_END_state";
        4:CS_tb_wp_rx="ERROR_state";
    endcase
 end

  // =========================
  // Tasks
  // =========================
  task reset_dut;
    begin
      $display("time at %0t in reset",$time);
      i_rst_n = 0;
      repeat(3) @(posedge i_clk);
      i_rst_n = 1;
      @(posedge i_clk);
      $display( "reset removed at time = %0t", $time);
    end
  endtask



  
  task NORMAL_FLOW;
    begin
      i_sb_busy = 1;
      $strobe("SB IS BUSY AT TIME = %0t",$time);
      $display("Normal flow task started at time = %0t" ,$time);      // enable
      $display("i_sbinit_en raised to 1 at time = %0t", $time);
      i_SBINIT_en = 1;
      @(posedge i_clk);
      $strobe("tx CS is %s and rx CS is %s" ,CS_tb_wp_tx , CS_tb_wp_rx);
      i_start_pattern_done = 1;
      $strobe("TX_CS expected state is start_sb_pattern and its = %s  and rx expected state is wait done req and its RX_CS = %s",CS_tb_wp_tx,CS_tb_wp_rx);
      @(posedge i_clk);
      i_start_pattern_done = 0;
      $strobe("i_start pattern pulse done at time = %0t ",$time);
      $strobe("TX_CS expected state is start_sb_pattern and its = %s  and rx expected state is wait done req and its RX_CS = %s",CS_tb_wp_tx,CS_tb_wp_rx);
      @(posedge i_clk);
      @(posedge i_clk);
      i_sb_busy = 0;
      i_rx_msg_valid = 1;
      @(posedge i_clk);
      $strobe("NOW sb is not busy and is ready to recieve at time = %0t",$time);
      while(o_tx_msg_valid!=0) @(posedge i_clk);
      $strobe("o_tx_msg_valid is raised to 1 at time %0t",$time);
      @(posedge i_clk);
      i_decoded_SB_msg = SBINIT_Out_of_Reset_msg; //out of reset msg
      @(posedge i_clk);
      $strobe("Expected state is wait_Sb_busy for tx and TX_CS = %s and rx expected state is wait done req and RX_CS = %d",CS_tb_wp_tx,CS_tb_wp_rx);  
      @(posedge i_clk);
      $strobe("Current TX_state is %d and Current RX_state is %d",CS_tb_wp_tx,CS_tb_wp_rx);
      i_decoded_SB_msg = SBINIT_done_req_msg;
      @(posedge i_clk);
      $strobe("expect tx_state is sbinit_done_req and TX_state is %d and expected rx state is sbinit done resp Current RX_state is %d at time =%0t",CS_tb_wp_tx,CS_tb_wp_rx,$time);
      @(posedge i_clk);
      i_decoded_SB_msg = SBINIT_done_resp_msg;
      @(posedge i_clk);
      $strobe("TX_state is %d and Current RX_state is %d at time =%0t",CS_tb_wp_tx,CS_tb_wp_rx,$time);
      @(posedge i_clk);
      @(posedge i_clk);
      @(posedge i_clk);
      $strobe("TX_state is %d and Current RX_state is %d at time =%0t",CS_tb_wp_tx,CS_tb_wp_rx,$time);
      $strobe("expected o_Sbinit_end is 1 and its %0d",o_SBINIT_end);
      @(posedge i_clk);
      @(posedge i_clk);
      $display("TB ENDED SUCCESSFULLY");
    end
  endtask

  // =========================
  // Init + run
  // =========================
  initial begin
    // defaults
    i_rst_n             = 1;
    i_SBINIT_en         = 0;
    i_start_pattern_done= 0;
    i_rx_msg_valid      = 0;
    i_decoded_SB_msg    = 0;

    // start busy by default
    i_sb_busy           = 1;

    reset_dut();
    NORMAL_FLOW();

    $stop;
  end

endmodule
