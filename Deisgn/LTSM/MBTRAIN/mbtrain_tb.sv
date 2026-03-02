`timescale 1ns/1ps
//==============================================================================
// Simple MBTRAIN wrapper testbench (transactional, no waveform digging)
// - Drives MBTRAIN from reset -> full flow -> MBTRAIN_FINISH
// - Emulates "partner die" sideband responses (START_RESP / END_RESP style)
// - Emulates point-test acks for TX and RX
// - Pulses i_falling_edge_busy whenever DUT asserts o_valid (HOLD-UNTIL-DONE model)
// - Prints key events (substate + message) and ends with TB PASS when o_mbtrain_ack=1
//
// NOTE:
// 1) This TB assumes each sub-wrapper uses a simple 4-msg handshake family:
//    START_REQ(0001), START_RSP(0010), END_REQ(0011), END_RSP(0100)
//    If any sub-wrapper uses different codes, adjust the localparams.
// 2) If your DUT expects payload on i_sideband_data / i_sideband_data_lanes_encoding,
//    we drive reasonable defaults.
//==============================================================================

module tb_mbtrain_wrapper;

  //--------------------------------------------------------------------------
  // Clock/reset
  //--------------------------------------------------------------------------
  reg clk;
  reg rst_n;

  //--------------------------------------------------------------------------
  // DUT inputs
  //--------------------------------------------------------------------------
  reg         i_en;

  // sideband
  reg  [3:0]  i_sideband_message;           // decoded msg from OTHER die
  reg  [15:0] i_sideband_data;              // optional payload from OTHER die
  reg         i_busy;                       // optional (not used by many blocks)
  reg         i_falling_edge_busy;          // "TX done" pulse
  reg         i_sideband_valid;             // decoded valid from OTHER die
  reg  [2:0]  i_sideband_data_lanes_encoding; // partner lane encoding (REPAIR RX uses)

  // point test (local)
  reg         i_tx_point_test_ack;
  reg         i_rx_point_test_ack;
  reg  [15:0] i_tx_lanes_result;
  reg  [15:0] i_rx_lanes_result;

  // framing error (local)
  reg         i_valid_framing_error;

  // LTSM resolved (entry selection)
  reg  [1:0]  i_phyretrain_resolved_state;

  // MBINIT inputs
  reg  [2:0]  i_highest_common_speed;
  reg         i_first_8_tx_lanes_are_functional_mbinit, i_second_8_tx_lanes_are_functional_mbinit;
  reg         i_first_8_rx_lanes_are_functional_mbinit, i_second_8_rx_lanes_are_functional_mbinit;

  reg  [3:0]  i_reciever_ref_voltage;

  //--------------------------------------------------------------------------
  // DUT outputs
  //--------------------------------------------------------------------------
  wire [3:0]  o_sideband_substate;
  wire [3:0]  o_sideband_message;
  wire [2:0]  o_sideband_data_lanes_encoding;
  wire        o_timeout_disable;
  wire        o_valid;

  wire [3:0]  o_reciever_ref_voltage;
  wire [3:0]  o_pi_step;

  wire        o_tx_mainband_or_valtrain_test;
  wire        o_tx_lfsr_or_perlane;
  wire        o_rx_mainband_or_valtrain_test;

  wire        o_tx_pt_en, o_rx_pt_en;
  wire        o_tx_eye_width_sweep_en, o_rx_eye_width_sweep_en;

  wire [1:0]  o_phyretrain_error_encoding;
  wire        o_mbtrain_ack;

  wire        o_first_8_tx_lanes_are_functional, o_second_8_tx_lanes_are_functional;
  wire        o_first_8_rx_lanes_are_functional, o_second_8_rx_lanes_are_functional;

  wire        o_phyretrain_en;

  wire [2:0]  o_curret_operating_speed;

  //--------------------------------------------------------------------------
  // Instantiate DUT (mbtrain_wrapper)
  //--------------------------------------------------------------------------
  mbtrain_wrapper dut (
    .clk(clk),
    .i_en(i_en),
    .rst_n(rst_n),

    .i_sideband_message(i_sideband_message),
    .i_sideband_data(i_sideband_data),
    .i_busy(i_busy),
    .i_falling_edge_busy(i_falling_edge_busy),
    .i_sideband_valid(i_sideband_valid),
    .i_sideband_data_lanes_encoding(i_sideband_data_lanes_encoding),

    .i_tx_point_test_ack(i_tx_point_test_ack),
    .i_rx_point_test_ack(i_rx_point_test_ack),
    .i_tx_lanes_result(i_tx_lanes_result),
    .i_rx_lanes_result(i_rx_lanes_result),

    .i_valid_framing_error(i_valid_framing_error),

    .i_phyretrain_resolved_state(i_phyretrain_resolved_state),

    .i_highest_common_speed(i_highest_common_speed),
    .i_first_8_tx_lanes_are_functional_mbinit(i_first_8_tx_lanes_are_functional_mbinit),
    .i_second_8_tx_lanes_are_functional_mbinit(i_second_8_tx_lanes_are_functional_mbinit),
    .i_first_8_rx_lanes_are_functional_mbinit(i_first_8_rx_lanes_are_functional_mbinit),
    .i_second_8_rx_lanes_are_functional_mbinit(i_second_8_rx_lanes_are_functional_mbinit),

    .i_reciever_ref_voltage(i_reciever_ref_voltage),

    .o_sideband_substate(o_sideband_substate),
    .o_sideband_message(o_sideband_message),
    .o_sideband_data_lanes_encoding(o_sideband_data_lanes_encoding),
    .o_timeout_disable(o_timeout_disable),
    .o_valid(o_valid),

    .o_reciever_ref_voltage(o_reciever_ref_voltage),
    .o_pi_step(o_pi_step),

    .o_tx_mainband_or_valtrain_test(o_tx_mainband_or_valtrain_test),
    .o_tx_lfsr_or_perlane(o_tx_lfsr_or_perlane),
    .o_rx_mainband_or_valtrain_test(o_rx_mainband_or_valtrain_test),

    .o_tx_pt_en(o_tx_pt_en),
    .o_rx_pt_en(o_rx_pt_en),
    .o_tx_eye_width_sweep_en(o_tx_eye_width_sweep_en),
    .o_rx_eye_width_sweep_en(o_rx_eye_width_sweep_en),

    .o_phyretrain_error_encoding(o_phyretrain_error_encoding),

    .o_mbtrain_ack(o_mbtrain_ack),

    .o_first_8_tx_lanes_are_functional(o_first_8_tx_lanes_are_functional),
    .o_second_8_tx_lanes_are_functional(o_second_8_tx_lanes_are_functional),
    .o_first_8_rx_lanes_are_functional(o_first_8_rx_lanes_are_functional),
    .o_second_8_rx_lanes_are_functional(o_second_8_rx_lanes_are_functional),

    .o_phyretrain_en(o_phyretrain_en),

    .o_curret_operating_speed(o_curret_operating_speed)
  );

  //--------------------------------------------------------------------------
  // Clock
  //--------------------------------------------------------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk; // 100 MHz

  //--------------------------------------------------------------------------
  // Common sideband codes (adjust if your standard mapping differs)
  //--------------------------------------------------------------------------
  localparam [3:0] START_REQ = 4'b0001;
  localparam [3:0] START_RSP = 4'b0010;
  localparam [3:0] END_REQ   = 4'b0011;
  localparam [3:0] END_RSP   = 4'b0100;

  //--------------------------------------------------------------------------
  // Helpers
  //--------------------------------------------------------------------------
  task wait_cycles(input integer n);
    integer i;
    begin
      for (i=0; i<n; i=i+1) @(negedge clk);
    end
  endtask

  // Inject partner-decoded message into DUT RX
  task partner_send_msg(input [3:0] msg);
    begin
      @(negedge clk);
      i_sideband_message = msg;
      i_sideband_valid   = 1'b1;
      @(negedge clk);
      i_sideband_valid   = 1'b0;
      i_sideband_message = 4'b0000;
    end
  endtask

  // Pulse "TX done" (busy falling edge)
  task pulse_tx_done;
    begin
      @(negedge clk);
      i_falling_edge_busy = 1'b1;
      @(negedge clk);
      i_falling_edge_busy = 1'b0;
    end
  endtask

  //--------------------------------------------------------------------------
  // Transactional “partner model”
  // - When DUT asserts o_valid, we:
  //   1) print msg + substate
  //   2) complete local TX by pulsing i_falling_edge_busy
  //   3) send back the expected response (START_RSP for START_REQ, END_RSP for END_REQ)
  //--------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n && i_en && o_valid) begin
      $display("[%0t] DUT TX: substate=%0d msg=%b speed=%0d",
               $time, o_sideband_substate, o_sideband_message, o_curret_operating_speed);

      // Complete the transmit (HOLD-UNTIL-DONE)
      fork
        begin
          wait_cycles(1);
          pulse_tx_done();
        end
      join_none

      // Partner response logic (simple generic handshake)
      if (o_sideband_message == START_REQ) begin
        fork
          begin
            wait_cycles(3);
            partner_send_msg(START_RSP);
            $display("[%0t] PARTNER RX->DUT: START_RSP", $time);
          end
        join_none
      end
      else if (o_sideband_message == END_REQ) begin
        fork
          begin
            wait_cycles(3);
            partner_send_msg(END_RSP);
            $display("[%0t] PARTNER RX->DUT: END_RSP", $time);
          end
        join_none
      end
    end
  end

  //--------------------------------------------------------------------------
  // Point-test model
  // - When DUT enables TX or RX point test, we ack after a short delay.
  // - Provide deterministic lane results (all-good).
  //--------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n && i_en) begin
      if (o_tx_pt_en) begin
        fork
          begin
            wait_cycles(8);
            i_tx_lanes_result    <= 16'hFFFF;
            @(negedge clk) i_tx_point_test_ack <= 1'b1;
            @(negedge clk) i_tx_point_test_ack <= 1'b0;
            $display("[%0t] TX point-test ACK", $time);
          end
        join_none
      end
      if (o_rx_pt_en) begin
        fork
          begin
            wait_cycles(8);
            i_rx_lanes_result    <= 16'hFFFF;
            @(negedge clk) i_rx_point_test_ack <= 1'b1;
            @(negedge clk) i_rx_point_test_ack <= 1'b0;
            $display("[%0t] RX point-test ACK", $time);
          end
        join_none
      end
    end
  end

  //--------------------------------------------------------------------------
  // Main test sequence
  //--------------------------------------------------------------------------
  initial begin
    // defaults
    rst_n = 1'b0;
    i_en  = 1'b0;

    i_sideband_message = 4'b0000;
    i_sideband_data    = 16'h0000;
    i_busy             = 1'b0;
    i_falling_edge_busy= 1'b0;
    i_sideband_valid   = 1'b0;

    i_sideband_data_lanes_encoding = 3'b000; // partner says both 8-lane groups OK by default

    i_tx_point_test_ack = 1'b0;
    i_rx_point_test_ack = 1'b0;
    i_tx_lanes_result   = 16'hFFFF;
    i_rx_lanes_result   = 16'hFFFF;

    i_valid_framing_error = 1'b0;

    // Start from normal training entry
    i_phyretrain_resolved_state = 2'b00;

    // MBINIT context
    i_highest_common_speed = 3'd3;
    i_first_8_tx_lanes_are_functional_mbinit  = 1'b1;
    i_second_8_tx_lanes_are_functional_mbinit = 1'b1;
    i_first_8_rx_lanes_are_functional_mbinit  = 1'b1;
    i_second_8_rx_lanes_are_functional_mbinit = 1'b1;

    i_reciever_ref_voltage = 4'h8;

    // reset release
    wait_cycles(5);
    rst_n = 1'b1;
    wait_cycles(2);

    // enable mbtrain
    i_en = 1'b1;
    $display("[%0t] MBTRAIN ENABLED", $time);

    // Run until finish or timeout
    begin : RUN_TO_DONE
      integer guard;
      guard = 0;
      while (o_mbtrain_ack !== 1'b1) begin
        wait_cycles(1);
        guard = guard + 1;
        if (guard > 3000) begin
          $display("ERROR: Timeout waiting for o_mbtrain_ack.");
          $display("Last: substate=%0d msg=%b valid=%b speed=%0d phy_en=%b",
                   o_sideband_substate, o_sideband_message, o_valid,
                   o_curret_operating_speed, o_phyretrain_en);
          $stop;
        end
      end
    end

    $display("[%0t] MBTRAIN DONE: o_mbtrain_ack=1, phyretrain_en=%0d, speed=%0d",
             $time, o_phyretrain_en, o_curret_operating_speed);

    // disable
    wait_cycles(5);
    i_en = 1'b0;

    wait_cycles(10);
    $display("TB PASS.");
    $stop;
  end

endmodule
