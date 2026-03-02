# ============================================================
# Questa/ModelSim DO file for MBINIT.PARAM Testbench
# ============================================================



# 2. Compile source files
vlib work


vlog -sv REPAIRCLK_Module.sv
vlog -sv RepairCLK_ModulePartner.sv
vlog -sv RepairCLK_Wrapper.sv
vlog -sv tb_repairclk.sv




# 3. Load testbench
vsim -c work.tb_REPAIRCLK -voptargs=+acc









