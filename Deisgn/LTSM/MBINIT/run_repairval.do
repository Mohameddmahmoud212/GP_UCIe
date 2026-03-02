# ============================================================
# Questa/ModelSim DO file for MBINIT.PARAM Testbench
# ============================================================



# 2. Compile source files
vlib work


vlog -sv REPAIRVAL_Module.v
vlog -sv REPAIRVAL_ModulePartner.v
vlog -sv REPAIRVAL_Wrapper.v
vlog -sv tb_repairval.sv




# 3. Load testbench
vsim -c work.tb_REPAIRVAL -voptargs=+acc









