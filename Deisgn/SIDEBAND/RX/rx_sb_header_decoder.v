module SB_RX_HEADER_DECODER (
	input 				i_clk,
	input 				i_rst_n,
	input 				i_header_decoder_enable,
	input		[63:0]  i_header_data,
	output 	reg			o_tx_point_sweep_test_en,
	output 	reg	[1:0]  	o_tx_point_sweep_test,
	output 	reg	[3:0]	o_msg_no,
	output 	reg	[2:0]	o_msg_info,
	output 	reg			o_dec_header_done,
	output 	reg          o_msg_with_data,
	output reg   [7:0]        o_msg_code_with_data, //added [7:0]
	output reg   [7:0]        o_msg_sub_code_with_data //added [7:0]
);

wire [4:0] opcode;
wire [7:0] MsgSubCode;
wire [7:0] MsgCode;
wire [15:0]MsgInfo;



assign opcode 	= i_header_data[4:0];
assign MsgSubCode = i_header_data[39:32];
assign MsgCode = i_header_data[21:14];
assign MsgInfo = i_header_data[55:40];

//CHECKING ON THESE IN IF CONDITIONS
wire test_msg, sbinit_msg, mbinit_msg, mbtrain_msg, phyretrain_msg, train_error_msg;


assign test_msg =   MsgCode [7:4] == 4'h8;
assign sbinit_msg = MsgCode [7:4] == 4'h9;
assign mbinit_msg = MsgCode [7:4] == 4'hA;
assign mbtrain_msg = MsgCode [7:4]== 4'hB;
assign phyretrain_msg = MsgCode[7:4] == 4'hC;
assign train_error_msg = MsgCode[7:4] == 4'hE;

//********************************test messages*************************//
always @(posedge i_clk or negedge i_rst_n) begin
  if(~i_rst_n) begin
    o_tx_point_sweep_test_en <= 1'b0;
    o_tx_point_sweep_test    <= 2'b00;
  end
  else if (i_header_decoder_enable) begin
    if (test_msg) begin
      o_tx_point_sweep_test_en <= 1'b1;
      case (MsgSubCode)
        8'h01, 8'h03, 8'h04         : o_tx_point_sweep_test <= 2'b00;
        8'h05, 8'h06                : o_tx_point_sweep_test <= 2'b01;
        8'h07, 8'h08, 8'h09         : o_tx_point_sweep_test <= 2'b10;
        8'h0A, 8'h0B, 8'h0C, 8'h0D  : o_tx_point_sweep_test <= 2'b11;
        default                     : o_tx_point_sweep_test <= 2'b00;
      endcase
    end else begin
      o_tx_point_sweep_test_en <= 1'b0;
      o_tx_point_sweep_test    <= 2'b00;   // 
    end
  end else begin
    o_tx_point_sweep_test_en <= 1'b0;      // 
    o_tx_point_sweep_test    <= 2'b00;
  end
end


//******************************returning the messsage number and msginfo**************************//
always @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		o_msg_no<=0;
		o_msg_info<=0;
		o_msg_with_data<=0;
		o_msg_code_with_data<=0;
		o_msg_sub_code_with_data<=0;
	end
	else if (i_header_decoder_enable)begin
		o_msg_no<=0;//default
		o_msg_info<=0;//default
		o_msg_with_data<=0;//default
		o_msg_code_with_data<=0;//default
		o_msg_sub_code_with_data<=0;//defualt
		//1 sbinit msgs
		if(sbinit_msg) begin
			case(MsgCode[3:0])
				4'h5:begin 
					o_msg_no<=1;
					o_msg_info<=0;
				end
				4'hA:begin
					o_msg_no<=2;
					o_msg_info<=0;
				end
				4'h1:begin
					o_msg_no<=3;
					o_msg_info<=0;
				end
			default:begin
				o_msg_info<=0;
				o_msg_no<=0;
			end		
			endcase
		end
		//2 mbinit msgs
		else if(mbinit_msg) begin
			case(MsgSubCode) 
				8'h00:begin
						o_msg_info<=0;
						o_msg_with_data<=1;
						o_msg_code_with_data<=MsgCode;
						o_msg_sub_code_with_data<=MsgSubCode;
						case(MsgCode[3:0])
							4'h5:o_msg_no<=1;
							4'hA:o_msg_no<=2;
							default:begin
								o_msg_info<=0;
								o_msg_no<=0;
								o_msg_with_data<=0;
								o_msg_code_with_data<=0;
								o_msg_sub_code_with_data<=0;
							end
						endcase
					end

				8'h02:begin
					o_msg_info<=0;
					case(MsgCode[3:0])
						4'h5:o_msg_no<=1;
						4'hA:o_msg_no<=2;
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h03:begin
					o_msg_info<=0;
					case(MsgCode[3:0])
						4'h5:o_msg_no<=1;
						4'hA:o_msg_no<=2;
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h04:begin
					o_msg_info<=0;
					case(MsgCode[3:0])
						4'h5:o_msg_no<=1;
						4'hA:o_msg_no<=2;
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h08:begin
					o_msg_info<=0;
					case(MsgCode[3:0])
						4'h5:o_msg_no<=1;
						4'hA:o_msg_no<=2;
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h09:begin
					o_msg_info<=0;
					case(MsgCode[3:0])
						4'h5:o_msg_no<=1;
						4'hA:o_msg_no<=2;
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h0A:begin
					case(MsgCode[3:0])
						4'h5:begin
							o_msg_no<=1;
						end
						4'hA:begin
							o_msg_no<=2;
							o_msg_info<=MsgInfo[2:0];
						end
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h0C:begin
					o_msg_info<=0;
					case(MsgCode[3:0])
						4'h5:o_msg_no<=1;
						4'hA:o_msg_no<=2;
						default:begin
							o_msg_info<=0;
							o_msg_no<=0;
						end
					endcase
				end
				8'h0D:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end

				8'h0E:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end
				8'h0F:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end
				8'h10:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end
				8'h11:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end
				8'h13:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end
				8'h14:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:begin
						o_msg_no<=1;
						o_msg_info<=MsgInfo[2:0];
					end
					4'hA: begin		
						o_msg_no<=2;
						o_msg_info<=0;
					end
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
				end
	
			default:begin
				o_msg_info<=0;
				o_msg_no<=0;
			end
			endcase
	end
	//mbtrain msgs
	else if(mbtrain_msg)begin
		case(MsgSubCode) 
			8'h00:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h01:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h02:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h03:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h04:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h05:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:begin
						o_msg_no<=1;
					end
					4'hA:begin
						o_msg_no<=2;
					end
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h06:begin
				o_msg_info<=0;
				case(MsgCode[3:0])
					4'h5:o_msg_no<=1;
					4'hA:o_msg_no<=2;
					default:begin
						o_msg_info<=0;
						o_msg_no<=0;
					end
				endcase
			end
			8'h07:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:o_msg_no<=1;
				4'hA:o_msg_no<=2;
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h08:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:o_msg_no<=1;
				4'hA:o_msg_no<=2;
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h09:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:o_msg_no<=1;
				4'hA:o_msg_no<=2;
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h0A:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:o_msg_no<=1;
				4'hA:o_msg_no<=2;
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h0B:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:o_msg_no<=1;
				4'hA:o_msg_no<=2;
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h0C:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:o_msg_no<=1;
				4'hA:o_msg_no<=2;
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h0D:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h0E:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h10:begin
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h11:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h12:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h13:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end
			8'h14:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h15:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h16:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h17:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h18:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h19:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h1F:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h1B:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			8'h1D:begin
			o_msg_info<=0;
			case(MsgCode[3:0])
				4'h5:begin
					o_msg_no<=1;
				end
				4'hA: begin		
					o_msg_no<=2;
				end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
			endcase
			end

			default:begin
				o_msg_info<=0;
				o_msg_no<=0;
			end
		endcase
	end
	//phyretrain msgs
	else if (phyretrain_msg) begin
		case (MsgSubCode)
			8'h01:begin
				o_msg_info <=MsgInfo[2:0];
				case(MsgCode[3:0])
					4'h5:begin
						o_msg_no<=1;
					end
					4'hA:begin
						o_msg_no<=2;
					end
				endcase
			end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
		endcase
	end
	//trainerror msgs
	else if(train_error_msg) begin
		case (MsgSubCode)
			8'h00:begin
				o_msg_info <=0;
				case(MsgCode[3:0])
					4'h5:begin
						o_msg_no<=1;
					end
					4'hA:begin
						o_msg_no<=2;
					end
				default:begin
					o_msg_info<=0;
					o_msg_no<=0;
				end
				endcase
			end
			default:begin
				o_msg_info<=0;
				o_msg_no<=0;
			end
		endcase
	end		
	//test msgs taken..,,..
	else if (test_msg) begin
			case (MsgSubCode)
				8'h01, 8'h05, 8'h07, 8'h0A://------------------------------------------------------------------------------
				  	begin
				  		case (MsgCode [3:0])
				  			4'h5://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 1;
				  					//o_msg_info 	<= ??; //******************
 				  				end
				  			//------------------------------------------------------------------------------
				  			4'hA://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 2;
				  					o_msg_info 	<= 0; //******************
 				  				end
				  			//------------------------------------------------------------------------------
				  			default	: begin
				  				o_msg_no 	<= 0;
				  				o_msg_info 	<= 0;		
				  			end
				  		endcase
				  	end
				//------------------------------------------------------------------------------
			
				8'h02://------------------------------------------------------------------------------
				  	begin
				  		o_msg_info 	<= 0;
				  		case (MsgCode [3:0])
				  			4'h5://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 3;
 				  				end
				  			//------------------------------------------------------------------------------
				  			4'hA://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 4;
 				  				end
				  			//------------------------------------------------------------------------------
				  			default	: begin
				  				o_msg_no 	<= 0;
				  				o_msg_info 	<= 0;		
				  			end
				  		endcase
				  	end
				//------------------------------------------------------------------------------
			
				8'h03, 8'h0B://------------------------------------------------------------------------------
				  	begin
				  		case (MsgCode [3:0])
				  			4'h5://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 5;
				  					o_msg_info 	<= 0;
 				  				end
				  			//------------------------------------------------------------------------------
				  			4'hA://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 6;
				  					//o_msg_info 	<= MsgInfo [5:4]; //****************** this is wrong
 				  				end
				  			//------------------------------------------------------------------------------
				  			default	: begin
				  				o_msg_no 	<= 0;
				  				o_msg_info 	<= 0;		
				  			end
				  		endcase
				  	end
				//------------------------------------------------------------------------------

				8'h04, 8'h09, 8'h0D://------------------------------------------------------------------------------
				  	begin
				  		o_msg_info 	<= 0;
				  		case (MsgCode [3:0])
				  			4'h5://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 7;
 				  				end
				  			//------------------------------------------------------------------------------
				  			4'hA://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 8;
 				  				end
				  			//------------------------------------------------------------------------------
				  			default	: begin
				  				o_msg_no 	<= 0;
				  				o_msg_info 	<= 0;		
				  			end
				  		endcase
				  	end
				//------------------------------------------------------------------------------

				8'h06, 8'h08://------------------------------------------------------------------------------
				  	begin
				  		o_msg_info 	<= 0;
				  		case (MsgCode [3:0])
				  			4'h5://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 5;
 				  				end
				  			//------------------------------------------------------------------------------
				  			4'hA://------------------------------------------------------------------------------
				  				begin
				  					o_msg_no  	<= 6;
 				  				end
				  			//------------------------------------------------------------------------------
				  			default	: begin
				  				o_msg_no 	<= 0;
				  				o_msg_info 	<= 0;		
				  			end
				  		endcase
				  	end
				//------------------------------------------------------------------------------

				8'h0C://------------------------------------------------------------------------------
					begin
						o_msg_no 	<= 9;
						o_msg_info 	<= 0;
					end
				//------------------------------------------------------------------------------			
				default	: begin
					o_msg_no 	<= 0;
					o_msg_info 	<= 0;		
				end
			endcase
		end 
end //end of else if(i_header_decoder_enable)
end //end of always block

//*****************************decoder done********************************//
always @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		o_dec_header_done <= 0;
	end 
	else if (i_header_decoder_enable) begin
		o_dec_header_done <= 1;
	end
end

endmodule
