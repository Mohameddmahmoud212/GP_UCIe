module data_encoder (
    input 				i_clk,
	input 				i_rst_n, 
	input 				i_data_valid,
	input 				i_data_en,
	input 		[3:0] 	i_state, // ltsm 
	input 		[3:0] 	i_sub_state, //ltsm
	input 		[3:0] 	i_msg_no, // ltsm 
	input 		[15:0] 	i_data_bus, //
	// TEST Signals 
	input 				i_tx_point_sweep_test_en, //enable for point or sweep 
	input 		[1:0]  	i_tx_point_sweep_test,    // kind (mode ) of the test 
	// RDI Signals 
	output reg 	[63:0] 	o_data_encoded,
	output reg 			o_d_valid      // valid to tell packet framing that there is valid data on the bus afte encoded it

);

    
    // LINK STATE MACHINE :

    // 1 {Tx Init D to C point test req}
    // 2 {Rx Init D to C point test req}
    // 3 {Tx Init D to C results resp  }
    // 4 {Rx Init D to C results resp  }

    // 3 {Tx Init D to C eye sweep req }
    // 4 {Rx Init D to C eye sweep req }
    // 5 {Rx Init D to C sweep done with results}

    // 8  {MBINIT.PARAM configuration req  }
    // 9  {MBINIT.PARAM configuration resp }
    // 10 {MBINIT.PARAM SBFE req           } // optional (advanced )
    // 11 {MBINIT.PARAM SBFE resp          } // optional (advanced )

    // 12 {MBINIT.REVERSAL MB result resp  }
    // 13 {MBINIT.REPAIRMB Apply repair req}
    // 14 {MBTRAIN.REPAIR Apply repair req }


    localparam SBINIT     = 0;
	localparam MBINIT     = 1;
	localparam MBTRAIN    = 2;
	localparam PHYRETRAIN = 3;
	localparam TRAINERROR = 4; //not implemented yet

    //--------------------------------------------------------------------------
    // State encoding (minimal)
    //--------------------------------------------------------------------------
    // Sub-States parameters of MBINIT
    localparam PARAM 		 			= 0;
    localparam CAL 			 			= 1;
    localparam REPAIRCLK 		 		= 2;
    localparam REPAIRVAL 		 		= 3;
    localparam REVERSALMB 		 		= 4;
    localparam REPAIRMB 			 	= 5;

    // Sub-States parameters of MBTRIIN
    localparam VALREF 		 			= 0;
    localparam DATAVREF 	 			= 1;
    localparam SPEEDIDLE  				= 2;
    localparam TXSELFCAL 		 		= 3;
    localparam RXCLKCAL 				= 4;
    localparam VALTRAINCENTER 		 	= 5;
    localparam VALTRAINVREF 			= 6;
    localparam DATATRAINCENTER1 		= 7;
    localparam DATATRAINVREF 			= 8;
    localparam RXDESKEW 				= 9;
    localparam DATATRAINCENTER2 		= 10;
    localparam LINKSPEED 				= 11;
    localparam REPAIR 					= 12;

    // Point Test / Eye Sweep parameters
    localparam TX_POINT_TEST  			= 0;
    localparam TX_EYE_SWEEP  			= 1;
    localparam RX_POINT_TEST  			= 2;
    localparam RX_EYE_SWEEP  			= 3;
// -------------------------------------------------------------------------
    // Helper wires
    // -------------------------------------------------------------------------
    always @(posedge i_clk or negedge i_rst_n) begin 
	if(~i_rst_n) begin
		o_data_encoded <= 0;
		o_d_valid <= 0;
	end 
    else begin
		if (i_data_en) begin
            if (i_tx_point_sweep_test_en && i_data_valid) begin // enable for the test and the data is valid 
				if (i_msg_no == 1) begin
					o_d_valid <= 1;
					o_data_encoded <= {{4{1'b0}},i_data_bus[4],{16{1'b1}},{16{1'b0}},{15{1'b0}},i_data_bus[3],{1{1'b0}},{2{1'b0}},i_data_bus[2:1],{3{1'b0}},{2{1'b0}},i_data_bus[0]}; 
				end
				else begin
					case (i_tx_point_sweep_test)

						TX_POINT_TEST: begin
							if (i_msg_no == 6) begin
								o_d_valid <= 1;
								o_data_encoded <= {{48{1'b0}},i_data_bus[15:0]};
							end
							else begin
								o_d_valid <= 1;
								o_data_encoded <= {64{1'b0}};
							end
						end 

						TX_EYE_SWEEP: begin
							o_d_valid <= 1;
							o_data_encoded <= {64{1'b0}};
						end 

						RX_POINT_TEST: begin
							if (i_msg_no == 6) begin
								o_d_valid <= 1;
								o_data_encoded <= {{48{1'b0}},i_data_bus[15:0]};
							end
							else begin
								o_d_valid <= 1;
								o_data_encoded <= {64{1'b0}};
							end
						end 

						RX_EYE_SWEEP: begin
							if (i_msg_no == 9) begin
								o_d_valid <= 1;
								o_data_encoded <= {{48{1'b0}},i_data_bus[15:0]};
							end
							else begin
								o_d_valid <= 1;
								o_data_encoded <= {64{1'b0}};
							end
						end 

					endcase
				end
				
			end
			else if (i_data_valid) begin
				o_d_valid <= 0;
				if (i_msg_no == 0) begin
					o_d_valid <= 0;
				end
				else begin
					case (i_state)
						MBINIT : begin
							case (i_sub_state)
								PARAM: begin
									o_d_valid <= 1;
									o_data_encoded <= {{53{1'b0}},i_data_bus[10:0]};  
								end 

								REVERSALMB : begin
									if (i_msg_no == 6) begin
										o_d_valid <= 1;
										o_data_encoded <= {{48{1'b0}},i_data_bus[15:0]};
                                        // it define the error of each lane if it pass or 
                                        // not comparing to error three should that must be zero
                                        // in this state so if the any lane has error it's bit 
                                        // will be 1 , since that we use only 16 lane so the other 
                                        // bits is reserved 
									end
								end 

								default : begin 
									o_d_valid <= 0;
									o_data_encoded <= {64{1'b0}};
								end 
							endcase
						end
					
						default : begin 
							o_d_valid <= 0;
							o_data_encoded <= {64{1'b0}};
						end 
					endcase
				end	
			end
			else begin
				o_d_valid <= 0;
				o_data_encoded <= {64{1'b0}};
			end
		end
		else begin
			o_d_valid <= 0;
		end
	end
end

endmodule  