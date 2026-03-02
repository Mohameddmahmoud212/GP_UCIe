# ============================================================
# Questa/ModelSim DO file for MBINIT.PARAM Testbench
# ============================================================



# 2. Compile source files
vlib work
vlog -sv param_reg.v

vlog -sv CHECKER_PARAM_Partner.v
vlog -sv PARAM_module.sv
vlog -sv PARAM_ModulePartner.sv
vlog -sv param_wrapper.v
vlog -sv TB_PARAM_MBINIT.sv



# 3. Load testbench
vsim -c work.TB_PARAM_MBINIT -voptargs=+acc









