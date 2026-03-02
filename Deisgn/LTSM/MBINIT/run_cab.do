# ============================================================
# Questa/ModelSim DO file for MBINIT.PARAM Testbench
# ============================================================



# 2. Compile source files
vlib work
vlog -sv param_reg.v

vlog -sv CAL_Module.v
vlog -sv CAL_RX_Module.v
vlog -sv CAL_TOP_WRAPPER.v
vlog -sv tb_calibration.sv




# 3. Load testbench
vsim -c work.CAL_TOP_WRAPPER_tb -voptargs=+acc









