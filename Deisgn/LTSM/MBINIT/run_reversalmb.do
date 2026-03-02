# ============================================================
# Questa/ModelSim DO file for MBINIT.PARAM Testbench
# ============================================================



# 2. Compile source files
vlib work


vlog -sv REVERSALMB_Module.v
vlog -sv REVERSALMB_ModulePartner.v
vlog -sv REVERSALMB_Wrapper.v
vlog -sv tb_reversalmb.sv




# 3. Load testbench
vsim -c work.tb_REVERSALMB -voptargs=+acc












