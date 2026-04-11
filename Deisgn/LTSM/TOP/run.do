# Create library
vlib work
vmap work work

# Compile Verilog files
vlog *.v

# Compile SystemVerilog files
vlog -sv *.sv

# Start simulation (change TB if needed)
vsim -voptargs=+acc work.LTSM_wrapper_tb
do MBTRAIN_wave.do



# Run simulation
run -all