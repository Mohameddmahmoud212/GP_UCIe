module SB_RX_WRAPPER (
    input 				i_clk,
    input               RXCKSB,
    input 				i_rst_n,
    //input               i_de_ser_done,
    input            	RXDATASB,

	input   [3:0]   i_state,
    output          o_tx_point_sweep_test_en,
    output  [1:0]   o_tx_point_sweep_test,
    //output          o_rx_sb_start_pattern,  not used does rx request to start pattern or its TX??
    output          o_msg_valid,
    output  [3:0]   o_msg_no,
    output  [2:0]   o_msg_info,
    output  [15:0]  o_data,
    output          o_sb_pattern_detect_done_rx
	);


    wire w_header_done;
    wire w_data_done;
    wire w_header_enable;
    wire w_data_enable;
    wire w_de_ser_done; 
    wire [63:0] w_deser_data;
    wire [7:0] w_msg_code_with_data; //added
    wire [7:0] w_msg_sub_code_with_data; //added
    wire w_msg_with_data;
    wire w_pkt_valid = w_msg_with_data && w_header_done && w_de_ser_done;
    wire w_div_clk;
    wire w_data16_valid; //added

SB_RX_DESER rx_deser_dut (
	.i_clk       (RXCKSB),
	.i_clk_pll   (i_clk), //fast clock in tb
	.i_rst_n     (i_rst_n),
	.ser_data_in (RXDATASB),
	//.i_de_ser_done_sampled(de_ser_done_sampled),
	.par_data_out(w_deser_data), // output
	.de_ser_done (w_de_ser_done)  //output
); //be done as them because of the 2 clocks

sb_rx_controller rx_fsm_dut (
	         .i_clk(i_clk),
             .i_rst_n(i_rst_n),
             .i_header_decoder_done(w_header_done),           
             .i_data_decoder_done(w_data_done) ,            
             .i_deser_data(w_deser_data),                    
             .i_data_valid(w_msg_with_data),                     

             .i_deser_done(w_de_ser_done),                    
             .o_header_decoder_enable(w_header_enable),         
             .o_data_decoder_enable(w_data_enable),           
             .o_msg_valid_rx(o_msg_valid),                   
            //output    o_sb_start_pattern_detect_rx,     // start pattern detection 
             .o_sb_pattern_detect_done_rx(o_sb_pattern_detect_done_rx)      
             );
  SB_RX_HEADER_DECODER SB_RX_HEADER_DECOEDER_DUT (
            .i_clk(i_clk),
            .i_rst_n(i_rst_n),
            .i_header_decoder_enable(w_header_enable),
            .i_header_data(w_deser_data),
            .o_tx_point_sweep_test_en(o_tx_point_sweep_test_en),
            .o_tx_point_sweep_test(o_tx_point_sweep_test),
            .o_msg_no(o_msg_no),
            .o_msg_info(o_msg_info),
            .o_dec_header_done(w_header_done),
            .o_msg_code_with_data(w_msg_code_with_data),
            .o_msg_sub_code_with_data(w_msg_sub_code_with_data),
            .o_msg_with_data(w_msg_with_data)  //input to controller to enable data decoder
);


SB_DATA_DECODER_MIN16 data_decoder_dut (
      .i_clk(i_clk),
      .i_rst_n(i_rst_n),
      .i_pkt_valid(w_pkt_valid),
      .i_msgcode(w_msg_code_with_data),
      .i_msgsubcode(w_msg_sub_code_with_data),
      .i_datafield(w_deser_data),
      .o_data16(o_data),
      .o_data16_valid(w_data16_valid), //optional edited from o_msg_valid
      .o_data_decoder_done(w_data_done) //added
     // .o_kind() 
);

clk_div8 clk_div8_dut (
     .i_clk(i_clk)  ,   
     .i_rst_n (i_rst_n),  
     .o_clk_div8(w_div_clk)
);

endmodule