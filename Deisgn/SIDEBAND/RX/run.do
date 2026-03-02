vlib work
vlog tx_clk_controller.v
vlog tx_clk_divider.v
vlog tx_data_encoder.v
vlog tx_FIFO.v
vlog tx_MUX_2_1.v
vlog tx_pattern_generator.v
vlog tx_sb_controller.v
vlog tx_sb_header_encoder.v
vlog tx_SB_packet_Framing.v
vlog tx_sb_wrapper.v
vlog tx_serializer.v


vlog rx_data_decoder.v rx_deserializer.v rx_wrapper.v rx_sb_header_decoder.v rx_clk_divider.v 

vlog -sv rx_fsm.sv sb_wrapper_tb.sv
vsim -voptargs=+acc work.sb_wrapper_tb
do sb_wave.do
do wave.do
run -all