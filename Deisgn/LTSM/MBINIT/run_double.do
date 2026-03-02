# ============================================================
# Questa/ModelSim DO file for MBINIT.PARAM Testbench
# ============================================================



# 2. Compile source files
vlib work
vlog -sv REVERSALMB_Module.v
vlog -sv REVERSALMB_ModulePartner.v
vlog -sv REVERSALMB_Wrapper.v

vlog -sv REPAIRMB_Module.v
vlog -sv REPAIRMB_Module_Partner.v
vlog -sv REPAIRMB_Wrapper.v

vlog -sv CHECKER_REPAIRMB_Module_Partner.v
vlog -sv Functional_Lane_Setup.v

vlog -sv TB_REPAIR_REVERSAL.sv





# 3. Load testbench
vsim -c work.TB_REPAIR_REVERSAL -voptargs=+acc









