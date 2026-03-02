module sb_wrapper(
    input i_clk,
    input i_rst_n,
    // msgs from ltsm 
    input i_data_valid,
    input i_msg_valid,
    input [3:0]i_state,
    input [3:0]i_sub_state,
    input [3:0]i_msg_no,
    input [2:0]i_msg_info,
    input i_tx_point_sweep_test_en,
    input [1:0]i_tx_point_sweep_test,
    input [15:0]i_data_bus,
    input i_start_pattern_req,
    input i_pattern_detected,

    input RXCKSB,
    input RXDATASB,

    output o_sb_busy,
    output TXDATASB,
    output o_pattern_time_out,
    output TXCKSB,
    output o_tx_point_sweep_test_en,
    output [1:0] o_tx_point_sweep_test,
    output o_msg_valid,
    output  [3:0]   o_msg_no,
    output  [2:0]   o_msg_info,
    output  [15:0]  o_data,
    output          o_sb_pattern_detect_done_rx   
);


sb_tx_wrapper tx_wrapper_dut(
   .i_clk(i_clk), 
   .i_rst_n(i_rst_n), 
   .i_data_valid(i_data_valid), 
   .i_msg_valid(i_msg_valid), 
   .i_state(i_state), 
   .i_sub_state(i_sub_state), 
   .i_msg_no(i_msg_no), 
   .i_msg_info(i_msg_info), 
   .i_tx_point_sweep_test_en(i_tx_point_sweep_test_en), 
   .i_tx_point_sweep_test(i_tx_point_sweep_test), 
   .i_data_bus(i_data_bus), 
   .i_start_pattern_req(i_start_pattern_req), 
   .i_pattern_detected(i_pattern_detected), 

   .o_sb_busy(o_sb_busy), 
   .TXDATASB(TXDATASB), 
   .o_pattern_time_out(o_pattern_time_out), 
   .TXCKSB(TXCKSB)
);

SB_RX_WRAPPER RX_WRAPPER_dut(
   .i_clk(i_clk), 
   .i_rst_n(i_rst_n), 
   .RXCKSB(RXCKSB), 
   .RXDATASB(RXDATASB), 
   .i_state(i_state),

   .o_tx_point_sweep_test_en(o_tx_point_sweep_test_en), 
   .o_tx_point_sweep_test(o_tx_point_sweep_test), 
   .o_msg_valid(o_msg_valid), 
   .o_msg_no(o_msg_no), 
   .o_msg_info(o_msg_info), 
   .o_data(o_data), 
   .o_sb_pattern_detect_done_rx(o_sb_pattern_detect_done_rx)
	);
endmodule