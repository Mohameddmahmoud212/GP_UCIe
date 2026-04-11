transcript on

# ---------------------------------
# Recreate work library
# ---------------------------------
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# ---------------------------------
# Include directories
# ---------------------------------
set INC_DIRS "+incdir+./ltsm +incdir+./sideband"

# ---------------------------------
# Compile all Verilog/SystemVerilog files in ltsm
# ---------------------------------
foreach file [glob -nocomplain ./ltsm/*.v] {
    eval vlog -work work $INC_DIRS $file
}
foreach file [glob -nocomplain ./ltsm/*.sv] {
    eval vlog -work work -sv $INC_DIRS $file
}

# ---------------------------------
# Compile all Verilog/SystemVerilog files in sideband
# ---------------------------------
foreach file [glob -nocomplain ./sideband/*.v] {
    eval vlog -work work $INC_DIRS $file
}
foreach file [glob -nocomplain ./sideband/*.sv] {
    eval vlog -work work -sv $INC_DIRS $file
}

# ---------------------------------
# Compile top and testbench
# ---------------------------------
eval vlog -work work $INC_DIRS ./ltsm_with_sideband_top.v
eval vlog -work work $INC_DIRS ./pulse_sync.v
eval vlog -work work -sv $INC_DIRS ./ltsm_with_sideband_tb.sv

# ---------------------------------
# Start simulation
# ---------------------------------
vsim -voptargs=+acc work.ltsm_with_sideband_tb

# ---------------------------------
# Load waveform script if exists
# ---------------------------------
if {[file exists ./wave.do]} {
    do ./wave.do
}

view wave
view structure
view signals

run -all
