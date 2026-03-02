# -------------------------------
# ModelSim DO file for point_test_wrapper
# -------------------------------

# Clear previous session
vsim -c -do "restart -f"

# Compile all Verilog files
vlog rx_initiated_point_test_tx.v
vlog rx_initiated_point_test_rx.v
vlog rx_initiated_point_test_wrapper.v
vlog tb_rx_initiated_point_test_wrapper.sv

vsim -voptargs=+acc work.tb_rx_initiated_point_test

add wave -position insertpoint  \
sim:/tb_rx_initiated_point_test/SB_MSG_WIDTH \
sim:/tb_rx_initiated_point_test/clk \
sim:/tb_rx_initiated_point_test/rst_n \
sim:/tb_rx_initiated_point_test/i_rx_d2c_pt_en \
sim:/tb_rx_initiated_point_test/i_datavref_or_valvref \
sim:/tb_rx_initiated_point_test/i_pattern_finished \
sim:/tb_rx_initiated_point_test/i_comparison_results \
sim:/tb_rx_initiated_point_test/i_rx_msg_valid \
sim:/tb_rx_initiated_point_test/i_decoded_SB_msg \
sim:/tb_rx_initiated_point_test/o_encoded_SB_msg \
sim:/tb_rx_initiated_point_test/o_tx_data_bus \
sim:/tb_rx_initiated_point_test/o_tx_msg_valid \
sim:/tb_rx_initiated_point_test/o_tx_data_valid \
sim:/tb_rx_initiated_point_test/o_rx_d2c_pt_done \
sim:/tb_rx_initiated_point_test/o_comparison_result \
sim:/tb_rx_initiated_point_test/o_val_pattern_en \
sim:/tb_rx_initiated_point_test/o_mainband_pattern_generator_cw \
sim:/tb_rx_initiated_point_test/o_comparison_valid_en \
sim:/tb_rx_initiated_point_test/o_mainband_pattern_comparator_cw \
sim:/tb_rx_initiated_point_test/pass_count \
sim:/tb_rx_initiated_point_test/fail_count
add wave -position insertpoint  \
sim:/tb_rx_initiated_point_test/dut/RX_inst/CS \
sim:/tb_rx_initiated_point_test/dut/RX_inst/NS
add wave -position insertpoint  \
sim:/tb_rx_initiated_point_test/dut/TX_inst/CS \
sim:/tb_rx_initiated_point_test/dut/TX_inst/NS

run -all

