# ===============================
# RX_FSM GROUP
# ===============================
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/IDLE
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/HEADER_DECODE
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/DATA_DECODE
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/GENERAL_DECODE

add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_clk
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_rst_n
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_header_decoder_done
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_data_decoder_done
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_deser_data
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_data_valid
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/i_deser_done

add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/o_header_decoder_enable
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/o_data_decoder_enable
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/o_msg_valid_rx
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/o_sb_pattern_detect_done_rx

add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/CS
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/NS
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/opcode
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/MsgSubCode
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/MsgCode
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/MsgInfo
add wave -group RX_FSM sim:/sb_rx_tb/sb_rx_wrapper/rx_fsm_dut/dstid


# ===============================
# RX_HEADER_DECODER GROUP
# ===============================
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/i_clk
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/i_rst_n
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/i_header_decoder_enable
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/i_header_data

add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_tx_point_sweep_test_en
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_tx_point_sweep_test
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_msg_no
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_msg_info
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_dec_header_done
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_msg_with_data
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_msg_code_with_data
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/o_msg_sub_code_with_data

add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/opcode
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/MsgSubCode
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/MsgCode
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/MsgInfo

add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/test_msg
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/sbinit_msg
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/mbinit_msg
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/mbtrain_msg
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/phyretrain_msg
add wave -group RX_HDR_DEC sim:/sb_rx_tb/sb_rx_wrapper/SB_RX_HEADER_DECOEDER_DUT/train_error_msg


# ===============================
# DATA_DECODER GROUP
# ===============================
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/MSGCODE_TEST_START_REQ
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/SUB_START_EYE_SWEEP
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/SUB_START_POINT_TEST
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/MSGCODE_PARAM
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/SUBCODE_PARAM
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/MSGCODE_REVERSAL
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/SUBCODE_REVERSAL

add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/i_clk
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/i_rst_n
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/i_pkt_valid
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/i_msgcode
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/i_msgsubcode
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/i_datafield

add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/o_data16
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/o_data16_valid
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/is_test_eye_sweep
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/is_test_point
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/is_param
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/is_reversal
add wave -group RX_DATA_DEC sim:/sb_rx_tb/sb_rx_wrapper/data_decoder_dut/o_data_decoder_done


# ===============================
# CLK_DIV8 GROUP
# ===============================
add wave -group CLK_DIV8 sim:/sb_rx_tb/sb_rx_wrapper/clk_div8_dut/i_clk
add wave -group CLK_DIV8 sim:/sb_rx_tb/sb_rx_wrapper/clk_div8_dut/i_rst_n
add wave -group CLK_DIV8 sim:/sb_rx_tb/sb_rx_wrapper/clk_div8_dut/o_clk_div8
add wave -group CLK_DIV8 sim:/sb_rx_tb/sb_rx_wrapper/clk_div8_dut/counter


# ===============================
# RX_DESERIALIZER GROUP
# ===============================
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/i_clk
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/i_clk_pll
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/i_rst_n
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/ser_data_in
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/par_data_out
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/de_ser_done
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/bit_count
add wave -group RX_DESER sim:/sb_rx_tb/sb_rx_wrapper/rx_deser_dut/shift_reg


# ===============================
# tb_Signals GROUP
# ===============================

add wave -group tb_Signals sim:/sb_rx_tb/i_clk 
add wave -group tb_Signals sim:/sb_rx_tb/RXCKSB 
add wave -group tb_Signals sim:/sb_rx_tb/i_rst_n 
add wave -group tb_Signals sim:/sb_rx_tb/RXDATASB 
add wave -group tb_Signals sim:/sb_rx_tb/i_state 
add wave -group tb_Signals sim:/sb_rx_tb/o_tx_point_sweep_test_en 
add wave -group tb_Signals sim:/sb_rx_tb/o_tx_point_sweep_test 
add wave -group tb_Signals sim:/sb_rx_tb/o_rx_sb_start_pattern 
add wave -group tb_Signals sim:/sb_rx_tb/o_msg_valid 
add wave -group tb_Signals sim:/sb_rx_tb/o_msg_no 
add wave -group tb_Signals sim:/sb_rx_tb/o_msg_info 
add wave -group tb_Signals sim:/sb_rx_tb/o_data 
add wave -group tb_Signals sim:/sb_rx_tb/o_sb_pattern_detect_done_rx 
add wave -group tb_Signals sim:/sb_rx_tb/bit_count 
add wave -group tb_Signals sim:/sb_rx_tb/shift_reg


# ===============================
# Run
# ===============================
run -all