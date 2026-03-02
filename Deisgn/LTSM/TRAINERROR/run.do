#############################################################
# QuestaSim DO File
# TRAINERROR Handshake Simulation
#############################################################



#############################################################
# Compile RTL
#############################################################

vlog -sv TX_TRAINERROR_HS.v
vlog -sv RX_TRAINERROR_HS.v
vlog -sv TRAINERROR_HS_WRAPPER.v

#############################################################
# Compile Testbench
#############################################################

vlog -sv TB_TRAINERROR_HS_WRAPPER.sv

#############################################################
# Start Simulation
#############################################################

vsim -voptargs=+acc work.TB_TRAINERROR_HS_WRAPPER

#############################################################
# Add Waves
#############################################################

add wave -divider "CLOCK & RESET"
add wave sim:/TB_TRAINERROR_HS_WRAPPER/i_clk
add wave sim:/TB_TRAINERROR_HS_WRAPPER/i_rst_n

add wave -divider "CONTROL"
add wave sim:/TB_TRAINERROR_HS_WRAPPER/i_trainerror_en
add wave sim:/TB_TRAINERROR_HS_WRAPPER/i_rx_msg_valid
add wave sim:/TB_TRAINERROR_HS_WRAPPER/i_decoded_SB_msg

add wave -divider "WRAPPER OUTPUTS"
add wave sim:/TB_TRAINERROR_HS_WRAPPER/o_encoded_SB_msg
add wave sim:/TB_TRAINERROR_HS_WRAPPER/o_tx_msg_valid
add wave sim:/TB_TRAINERROR_HS_WRAPPER/o_TRAINERROR_HS_end

add wave -divider "TX INTERNAL"
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_TX_TRAINERROR_HS/CS
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_TX_TRAINERROR_HS/NS
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_TX_TRAINERROR_HS/o_valid_tx
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_TX_TRAINERROR_HS/o_trainerror_end_tx

add wave -divider "RX INTERNAL"
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_RX_TRAINERROR_HS/CS
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_RX_TRAINERROR_HS/NS
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_RX_TRAINERROR_HS/o_valid_rx
add wave sim:/TB_TRAINERROR_HS_WRAPPER/dut/U_RX_TRAINERROR_HS/o_trainerror_end_rx

#############################################################
# Run Simulation
#############################################################

run -all