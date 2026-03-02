`timescale 1ns/1ps
module TB_PHYRETRAIN_WRAPPER;

localparam SB_MSG_WIDTH = 4;
localparam [SB_MSG_WIDTH-1:0] PHYRETRAIN_START_REQ  = 1;  //"PHYRETRAIN.retrain.start.req"
localparam [SB_MSG_WIDTH-1:0] PHYRETRAIN_START_RESP = 2;  //  //"PHYRETRAIN.retrain.start.rsp"

  // =========================
  // TB signals
  // =========================
reg 					  i_clk;
reg 				      i_rst_n;	
reg                       i_PHYRETRAIN_en;
reg                       i_enter_from_active_or_mbtrain; // 0: from ACTIVE, 1: from MBTRAIN.LINKSPEED
reg       [1:0]           i_link_status;       // lane status from linkspeed
reg                       i_reset_resolved_state; // clear resolved_state before a new training

// from SB
reg                           i_sb_busy;     // 1: SB busy, 0: SB ready
reg                           i_rx_msg_valid;   // SB received a message this cycle (decoded_msg valid)
reg       [SB_MSG_WIDTH-1:0]  i_decoded_SB_msg;// decoded SB message from partner
reg       [2:0]               i_rx_msg_info;      // partner retrain encoding (TXSELFCAL/REPAIR/SPEEDIDLE)

// To SB
wire [SB_MSG_WIDTH-1:0] o_encoded_SB_msg;
wire                   o_tx_msg_valid;   // selected valid (TX or RX)
wire      [2:0]              o_tx_msg_info;    // local retrain encoding (from TX)

// To LTSM
wire                         o_PHYRETRAIN_end;// both TX and RX finished PHYRETRAIN
wire      [2:0]              o_resolved_state ; // resolved next state from RX

  // =========================
  // DUT
  // =========================
  PHYRETRAIN_WRAPPER #(.SB_MSG_WIDTH(SB_MSG_WIDTH)) dut (
    .i_clk               (i_clk),
    .i_rst_n             (i_rst_n),
    .i_PHYRETRAIN_en         (i_PHYRETRAIN_en),
    .i_enter_from_active_or_mbtrain(i_enter_from_active_or_mbtrain),
    .i_link_status      (i_link_status),
    .i_reset_resolved_state           (i_reset_resolved_state),
    .i_sb_busy    (i_sb_busy),
    .i_rx_msg_valid    (i_rx_msg_valid),
    .i_decoded_SB_msg(i_decoded_SB_msg),
    .i_rx_msg_info(i_rx_msg_info),
    .o_encoded_SB_msg      (o_encoded_SB_msg),
    .o_tx_msg_valid (o_tx_msg_valid),
    .o_tx_msg_info(o_tx_msg_info),
    .o_PHYRETRAIN_end        (o_PHYRETRAIN_end),
	.o_resolved_state(o_resolved_state)
  );

  //enum to debug states in wave
   typedef enum{IDLE_state_TX,SEND_REQ_state_TX,WAIT_FOR_RESP_state_TX,PHYRETRAIN_END_state_TX} states_enum_TX;
   typedef enum{IDLE_state_RX,WAIT_FOR_REQ_state_RX,SEND_RESP_state_RX,PHYRETRAIN_END_state_RX } states_enum_RX;

   string CS_tb_wp_tx,CS_tb_wp_rx,NS_tb_wp_tx,NS_tb_wp_rx;

  // =========================
  // Clock
  // =========================
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end

//to easily debug states
 always@(*)begin
    case(dut.U_TX_PHYRETRAIN.CS) 

        0:CS_tb_wp_tx="IDLE_state";
        1:CS_tb_wp_tx="SEND_REQ_state_TX";
        2:CS_tb_wp_tx="WAIT_FOR_RESP_STATE_TX";
        3:CS_tb_wp_tx="PHYRETRAIN_END_STATE_TX";
    endcase
 end

 //to easily debug states
 always@(*)begin
    case(dut.U_RX_PHYRETRAIN.CS) 

        0:CS_tb_wp_rx="IDLE_state";
        1:CS_tb_wp_rx="WAIT_FOR_REQ_state_RX";
        2:CS_tb_wp_rx="SEND_RESP_state_RX";
        3:CS_tb_wp_rx="PHYRETRAIN_END_STATE_RX";
    endcase
 end

 always@(*)begin
    case(dut.U_TX_PHYRETRAIN.NS) 

        0:NS_tb_wp_tx="IDLE_state";
        1:NS_tb_wp_tx="SEND_REQ_state_TX";
        2:NS_tb_wp_tx="WAIT_FOR_RESP_STATE_TX";
        3:NS_tb_wp_tx="PHYRETRAIN_END_STATE_TX";
    endcase
 end

 always@(*)begin
    case(dut.U_RX_PHYRETRAIN.NS) 

        0:NS_tb_wp_rx="IDLE_state";
        1:NS_tb_wp_rx="WAIT_FOR_REQ_state_RX";
        2:NS_tb_wp_rx="SEND_RESP_state_RX";
        3:NS_tb_wp_rx="PHYRETRAIN_END_STATE_RX";
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
  integer timeout;
begin
  $display("\n*** FULL normal flow starting at %0t ***", $time);

  // Clean defaults
  i_rx_msg_valid   = 0;
  i_decoded_SB_msg = 0;

  // 1) SB initially busy, then becomes ready
  i_sb_busy = 1;
  @(negedge i_clk);
  @(negedge i_clk);
  i_sb_busy = 0;
  $display("[%0t] SB is now ready (i_sb_busy = %0d)", $time, i_sb_busy);

  // 2) Enable PHYRETRAIN
  i_PHYRETRAIN_en = 1;

  // Let state update happen
  @(posedge i_clk);
  $strobe("[%0t] TX_CS=%s, RX_CS=%s", $time, CS_tb_wp_tx, CS_tb_wp_rx);
  $strobe("      EXPECTED: TX=SEND_REQ_state_TX, RX=WAIT_FOR_REQ_state_RX");

  // 3) Wait until TX reaches WAIT_FOR_RESP (means TX REQ accepted)
  timeout = 0;
  while ((dut.U_TX_PHYRETRAIN.CS != 2) && (timeout < 80)) begin
    @(posedge i_clk);
    timeout = timeout + 1;
  end

  if (dut.U_TX_PHYRETRAIN.CS != 2) begin
    $strobe("[%0t] ERROR: TX did not reach WAIT_FOR_RESP within timeout", $time);
  end else begin
    $strobe("[%0t] TX reached WAIT_FOR_RESP (REQ accepted)", $time);
  end

  // ------------------------------------------------------------
  // 4) PARTNER sends REQ to us  => RX should go SEND_RESP
  // ------------------------------------------------------------
  @(negedge i_clk);
  i_rx_msg_valid   = 1;
  i_decoded_SB_msg = PHYRETRAIN_START_REQ;
  $strobe("[%0t] Partner sends REQ (decoded_SB_msg=1, rx_msg_valid=1)", $time);

  @(negedge i_clk);
  i_rx_msg_valid   = 0;
  i_decoded_SB_msg = 0;

  // Wait until RX reaches SEND_RESP (CS==2)
  timeout = 0;
  while ((dut.U_RX_PHYRETRAIN.CS != 2) && (timeout < 50)) begin
    @(posedge i_clk);
    timeout = timeout + 1;
  end

  if (dut.U_RX_PHYRETRAIN.CS != 2) begin
    $strobe("[%0t] ERROR: RX did not reach SEND_RESP within timeout", $time);
  end else begin
    $strobe("[%0t] RX reached SEND_RESP (about to transmit RESP)", $time);
  end

  // Wait until RX finishes (goes PHYRETRAIN_END, CS==3)
  timeout = 0;
  while ((dut.U_RX_PHYRETRAIN.CS != 3) && (timeout < 80)) begin
    @(posedge i_clk);
    timeout = timeout + 1;
  end

  if (dut.U_RX_PHYRETRAIN.CS != 3) begin
    $strobe("[%0t] ERROR: RX did not reach PHYRETRAIN_END within timeout", $time);
  end else begin
    $strobe("[%0t] RX reached PHYRETRAIN_END", $time);
  end

  // ------------------------------------------------------------
  // 5) PARTNER sends RESP to us => TX should go PHYRETRAIN_END
  // ------------------------------------------------------------
  @(negedge i_clk);
  i_rx_msg_valid   = 1;
  i_decoded_SB_msg = PHYRETRAIN_START_RESP;
  $strobe("[%0t] Partner sends RESP (decoded_SB_msg=2, rx_msg_valid=1)", $time);

  @(negedge i_clk);
  i_rx_msg_valid   = 0;
  i_decoded_SB_msg = 0;

  // Wait until TX reaches PHYRETRAIN_END (CS==3)
  timeout = 0;
  while ((dut.U_TX_PHYRETRAIN.CS != 3) && (timeout < 80)) begin
    @(posedge i_clk);
    timeout = timeout + 1;
  end

  if (dut.U_TX_PHYRETRAIN.CS != 3) begin
    $strobe("[%0t] ERROR: TX did not reach PHYRETRAIN_END within timeout", $time);
  end else begin
    $strobe("[%0t] TX reached PHYRETRAIN_END", $time);
  end

  // ------------------------------------------------------------
  // 6) Wrapper end should become 1 when both done flags are seen
  // ------------------------------------------------------------
  timeout = 0;
  while ((o_PHYRETRAIN_end != 1'b1) && (timeout < 50)) begin
    @(posedge i_clk);
    timeout = timeout + 1;
  end

  $strobe("[%0t] FINAL: TX_CS=%s, RX_CS=%s, o_PHYRETRAIN_end=%0b, o_resolved_state=%0b",
          $time, CS_tb_wp_tx, CS_tb_wp_rx, o_PHYRETRAIN_end, o_resolved_state);

  if (o_PHYRETRAIN_end != 1'b1) begin
    $strobe("[%0t] ERROR: wrapper o_PHYRETRAIN_end did not assert", $time);
  end else begin
    $strobe("[%0t] PASS: wrapper o_PHYRETRAIN_end asserted", $time);
  end

  // Extra cycles
  repeat(3) @(posedge i_clk);

  // De-assert enable
  i_PHYRETRAIN_en = 0;
  @(negedge i_clk);

  $strobe("*** NORMAL_FLOW_FULL finished at %0t ***\n", $time);
end
endtask



  // =========================
  // Init + run
  // =========================
  initial begin
    // defaults
    i_rst_n                 = 1;
    i_PHYRETRAIN_en         = 0;
    i_rx_msg_valid          = 0;
    i_decoded_SB_msg        = 0;
    i_sb_busy               = 1;       // start busy
    i_enter_from_active_or_mbtrain = 0;
    i_link_status           = 2'b01;   // no lane errors
    i_reset_resolved_state  = 0;
    i_rx_msg_info           = 3'b001;  // partner encoding = TXSELFCAL (for later tests)

    reset_dut();
    NORMAL_FLOW();
    $stop;
  end

endmodule
