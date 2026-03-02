# -------------------------------
# ModelSim DO file for point_test_wrapper
# -------------------------------

# Clear previous session
vsim -c -do "restart -f"

# Compile all Verilog files
vlog tx_initiated_point_test_tx_2.v
vlog tx_initiated_point_test_rx_2.v
vlog tx_initiated_point_test_wrapper.v
vlog tb_tx_initiated_point_test_wrapper.sv

