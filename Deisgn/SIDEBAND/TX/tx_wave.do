# ===============================
# PATTERN GENERATOR GROUP
# ===============================
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/i_clk
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/i_rst_n
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/i_start_pattern_req
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/i_pattern_detected
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/i_ser_done
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/o_start_pattern_done
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/o_pattern_time_out
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/o_pattern
add wave -group PATTERN_GEN sim:/sb_tx_tb/tb_dut/pattern_dut/o_pattern_valid

# ===============================
# CONTROLLER FSM GROUP
# ===============================

add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_clk
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_rst_n
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_start_pattern_req
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_start_pattern_done
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_msg_valid
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_data_valid
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_header_done
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_data_done
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_packet_done
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_SB_busy
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_fifo_empty
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_fifo_full
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_msg_with_data
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/i_iteration_finished

add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/o_header_encoder_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/o_data_encoder_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/o_frame_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/o_pattern_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/o_sb_busy

add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/CS
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/NS
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/encoder_header_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/encoder_data_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/frame_enable
add wave -group CONTROLLER sim:/sb_tx_tb/tb_dut/controller_dut/idle_flag_counter

# ===============================
# FIFO GROUP
# ===============================
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/i_clk
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/i_rst_n
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/i_write_enable
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/i_read_enable
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/i_data_in
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/o_data_out
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/o_empty
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/o_ser_done_sampled
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/o_full
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/memory
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/write_count
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/read_count
add wave -group FIFO sim:/sb_tx_tb/tb_dut/FIFO_d/o_empty_comb

# ===============================
# SERIALIZER GROUP
# ===============================
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/i_clk
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/i_rst_n
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/i_data
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/i_enable
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/TXDATASB
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/o_busy
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/shift_reg
add wave -group SERIALIZER sim:/sb_tx_tb/tb_dut/seri_d/bit_count

# ===============================
# MUX GROUP
# ===============================
add wave -group MUX sim:/sb_tx_tb/tb_dut/mux_d/i_packet
add wave -group MUX sim:/sb_tx_tb/tb_dut/mux_d/i_pattern
add wave -group MUX sim:/sb_tx_tb/tb_dut/mux_d/i_packet_valid
add wave -group MUX sim:/sb_tx_tb/tb_dut/mux_d/i_pattern_valid
add wave -group MUX sim:/sb_tx_tb/tb_dut/mux_d/o_final_packet

add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_clk
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_rst_n
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_data_valid
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_msg_valid
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_header_encoder_enable
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_state
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_sub_state
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_msg_no
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_msg_info
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/o_header_message_encoded
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/o_header_done
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_tx_point_sweep_test_en
add wave -group header_decoder sim:/sb_tx_tb/tb_dut/header_d/i_tx_point_sweep_test

add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_clk
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_rst_n
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_header
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_data
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_header_done
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_d_valid
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_ser_done
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/i_frame_en
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/o_final_packet
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/o_timeout_ctr_start
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/o_packet_done
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/cp
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/dp
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/cp_done
add wave -group packetizer sim:/sb_tx_tb/tb_dut/packetizer_dut/dp_done

add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_clk
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_rst_n
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_data_valid
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_data_en
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_state
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_sub_state
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_msg_no
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_data_bus
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_tx_point_sweep_test_en
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/i_tx_point_sweep_test
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/o_data_encoded
add wave -group data_encoder sim:/sb_tx_tb/tb_dut/data_encoder_dut/o_d_valid

add wave -group clk_dut sim:/sb_tx_tb/tb_dut/out_clk_dut/i_clk 
add wave -group clk_dut sim:/sb_tx_tb/tb_dut/out_clk_dut/i_rst_n 
add wave -group clk_dut sim:/sb_tx_tb/tb_dut/out_clk_dut/i_enable 
add wave -group clk_dut sim:/sb_tx_tb/tb_dut/out_clk_dut/o_iteration_finished 
add wave -group clk_dut sim:/sb_tx_tb/tb_dut/out_clk_dut/TXCKSB 
add wave -group clk_dut sim:/sb_tx_tb/tb_dut/out_clk_dut/counter 


add wave -group clk_div8 sim:/sb_tx_tb/tb_dut/clk_divider_dut/i_clk 
add wave -group clk_div8 sim:/sb_tx_tb/tb_dut/clk_divider_dut/i_rst_n 
add wave -group clk_div8 sim:/sb_tx_tb/tb_dut/clk_divider_dut/o_clk_div8 

# ===============================
# Run
# ===============================
run -all
