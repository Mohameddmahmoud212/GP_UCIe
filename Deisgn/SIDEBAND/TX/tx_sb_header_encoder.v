module sb_header_encoder(
    input i_clk,
    input i_rst_n,
    input i_data_valid,
    input i_msg_valid,//yaane 3ndy message 3yza ttb3t f mhtag a3ml encode
    input i_header_encoder_enable,//gyale ml sb_tx_controller
    input [3:0] i_state , //gyale ml ltsm ana f anhy state
    input [3:0] i_sub_state, //gyale ml ltsm ana f anhy substate
    input [3:0]	i_msg_no,
    input [2:0]	i_msg_info,
    output reg [61:0]o_header_message_encoded,
    output reg o_header_done,//httb3t ll sb_tx_controller eny khlst encoding 
    
    // Poit/Sweep Tests Signals 
	input 				i_tx_point_sweep_test_en,
	input 		[1:0]  	i_tx_point_sweep_test
);
//states
localparam SBINIT     = 0;
localparam MBINIT     = 1;
localparam MBTRAIN    = 2;
localparam PHYRETRAIN = 3;
localparam TRAINERROR = 4; //not implemented yet

//substates of mbinit
localparam PARAM 		 			= 0;
localparam CAL 			 			= 1;
localparam REPAIRCLK 		 		= 2;
localparam REPAIRVAL 		 		= 3;
localparam REVERSALMB 		 		= 4;
localparam REPAIRMB 			 	= 5;

//substates of mbtrain
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

reg [4:0] opcode;
reg [7:0] MsgSubcode;
reg [7:0] MsgCode;
reg [15:0]MsgInfo;

//SRCID AND DSTID
wire [2:0] srcid;
wire [2:0] dstid;
assign srcid = 3'b010;
assign dstid = 3'b110;

//to be handled
wire RX_INIT_D_TO_C_SWEEP_DONE_WITH_RESULTS_MSG;
wire TX_OR_RX_INT_D_TO_C_RESULTS_RESP;


//POINT/SWEEP Tests
localparam TX_INIT_POINT_TEST  		= 0;
localparam TX_INIT_SWEEP_TEST  		= 1;
localparam RX_INIT_POINT_TEST 		= 2;
localparam RX_INIT_SWEEP_TEST 		= 3;

assign RX_INIT_D_TO_C_SWEEP_DONE_WITH_RESULTS_MSG 	= i_msg_no == 9;
assign TX_OR_RX_INT_D_TO_C_RESULTS_RESP  			= i_tx_point_sweep_test_en && (i_tx_point_sweep_test == TX_INIT_POINT_TEST || i_tx_point_sweep_test == RX_INIT_SWEEP_TEST) && i_msg_no == 6;


reg enable_test;
 //opcode handling
always @(*) begin
    if(i_data_valid) begin
        opcode = 5'b11011;  //opcode of message with data
    end
    else begin
        opcode = 5'b10010;    //opcode of message without data
    end 
end


//MsgSubcode handling
always @(*) begin
    MsgSubcode = 8'h00;  // Default
    if(i_msg_valid) begin
        if(i_tx_point_sweep_test_en) begin
        // Handle Point/Sweep Test Messages
            case(i_tx_point_sweep_test)
                TX_INIT_POINT_TEST: begin
                case(i_msg_no)
                    1, 2: MsgSubcode = 8'h01;  // Start Tx Init D to C point test Req / Resp
                    3, 4: MsgSubcode = 8'h02;  // Clear Error Req / Resp
                    5, 6: MsgSubcode = 8'h03;  // Results Req / Resp
                    7, 8: MsgSubcode = 8'h04;  // End Tx Init D to C point test req / Resp
                endcase
                end
                
                TX_INIT_SWEEP_TEST: begin
                case(i_msg_no)
                    1, 2: MsgSubcode = 8'h05;  // Start Tx Init D to C eye sweep Req / Resp
                    3, 4: MsgSubcode = 8'h02;  // Clear Error Req / Resp
                    5, 6: MsgSubcode = 8'h06;  // End Tx Init D to C eye sweep Req / Resp
                endcase
                end
                
                RX_INIT_POINT_TEST: begin
                case(i_msg_no)
                    1, 2: MsgSubcode = 8'h07;  // Start Rx Init D to C point test Req / Resp
                    3, 4: MsgSubcode = 8'h02;  // Clear Error Req / Resp
                    5, 6: MsgSubcode = 8'h08;  // End Rx Init D to C point test Req / Resp
                    7, 8: MsgSubcode = 8'h09;  // End Rx Init D to C point test Req / Resp
                endcase
                end
                
                RX_INIT_SWEEP_TEST: begin
                case(i_msg_no)
                    1, 2: MsgSubcode = 8'h0A;  // Start Rx Init D to C eye sweep Req / Resp
                    3, 4: MsgSubcode = 8'h02;  // Clear Error Req / Resp
                    5, 6: MsgSubcode = 8'h0B;  // Results Req / Resp
                    7, 8: MsgSubcode = 8'h0D;  // End Rx Init D to C eye sweep Req / Resp
                    9 	: MsgSubcode = 8'h0C;  // Done Rx Init D to C eye sweep Resp with result
                endcase
                end
            endcase
        end
        else begin
            case(i_state)
                SBINIT: begin
                    case(i_msg_no)
                        1,2:MsgSubcode=8'h01;
                        3:MsgSubcode=8'h00;
                    endcase
                end
                MBINIT:begin
                    case(i_sub_state)
                        PARAM:
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h00;
                            endcase
                        CAL:
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h02;
                            endcase
                        REPAIRCLK: 
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h03;
                                3,4:MsgSubcode=8'h04;
                                5,6:MsgSubcode = 8'h08;

                            endcase
                        REPAIRVAL:
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h09;
                                3,4:MsgSubcode=8'h0A;
                                5,6:MsgSubcode = 8'h0C;
                            endcase
                        REVERSALMB:
                        case(i_msg_no)
                            1,2:MsgSubcode=8'h0D;
                            3,4:MsgSubcode=8'h0E;
                            5:MsgSubcode = 8'h0F; //RESULT_RESP {6} DOESNT EXIST WILL ASSUME ITS 0F
                            7,8:MsgSubcode = 8'h10;
                        endcase
                        REPAIRMB:
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h11;
                                3,4:MsgSubcode=8'h13;
                                5,6:MsgSubcode = 8'h14; 
                            endcase
                        /*Note:
                        MBINIT_PARAM_configuration_req , MBINIT_PARAM_configuration_resp 
                        Done in data encoderrr//
                        */
                    endcase   
                end
                MBTRAIN:begin
                    case(i_sub_state)
                        VALREF:begin
                        case(i_msg_no)
                            1,2:MsgSubcode=8'h00;
                            3,4:MsgSubcode=8'h01;
                        endcase
                        end
                        DATAVREF:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h02;
                                3,4:MsgSubcode=8'h03;
                            endcase
                        end
                        SPEEDIDLE:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h04;
                            endcase
                        end
                        TXSELFCAL:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h05;
                            endcase
                        end
                        RXCLKCAL:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h06;
                                3,4:MsgSubcode=8'h07;
                            endcase
                        end
                        VALTRAINCENTER:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h08;
                                3,4:MsgSubcode=8'h09;
                            endcase
                        end
                        VALTRAINVREF:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h0A;
                                3,4:MsgSubcode=8'h0B;
                            endcase
                        end
                        DATATRAINCENTER1:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h0C;
                                3,4:MsgSubcode=8'h0D;
                            endcase
                        end
                        DATATRAINVREF:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h0E;
                                3,4:MsgSubcode=8'h10;
                            endcase
                        end
                        RXDESKEW:begin

                            case(i_msg_no)
                                1,2:MsgSubcode=8'h11;
                                3,4:MsgSubcode=8'h12;
                            endcase
                        end
                        DATATRAINCENTER2:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h13;
                                3,4:MsgSubcode=8'h14;
                            endcase
                        end

                        LINKSPEED:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h15;
                                3,4:MsgSubcode=8'h16;
                                5,6:MsgSubcode=8'h17;
                                7,8:MsgSubcode=8'h18;
                            endcase

                        end
                        REPAIR:begin
                            case(i_msg_no)
                                1,2:MsgSubcode=8'h1B;
                                3,4:MsgSubcode=8'h1D;
                            endcase
                        end
                    endcase
                end
                PHYRETRAIN:
                    case(i_msg_no)
                        1,2:MsgSubcode=8'h01;
                    endcase
                TRAINERROR:
                    case(i_msg_no)
                        1,2:MsgSubcode=8'h00;
                    endcase
                default:MsgSubcode = 8'h00;
        endcase
        end
    end
end
//handling MsgCode//
always @(*) begin
    MsgCode = 8'h00; // default
    if (i_msg_valid) begin
		if (i_tx_point_sweep_test_en) begin
			MsgCode [7:4] = 4'h8;
			if (RX_INIT_D_TO_C_SWEEP_DONE_WITH_RESULTS_MSG) begin
				MsgCode [3:0] = 4'h1;
			end
			else begin
				if (i_msg_no[0]) begin //1 3 5 7 ...
					MsgCode [3:0] = 4'h5;
				end
				else begin
					MsgCode [3:0] = 4'hA;
				end
			end
		end
        else begin 
            case(i_state)
                SBINIT:begin
                    case(i_msg_no)
                        1:MsgCode[3:0] = 4'h5;
                        2:MsgCode[3:0] = 4'hA;
                        3:MsgCode[3:0] = 4'h1;
                    endcase
                    MsgCode[7:4] = 4'h9;
                end
                MBINIT:begin
                    case(i_msg_no)
                        1:MsgCode[3:0] = 4'h5;
                        2:MsgCode[3:0] = 4'hA;
                    endcase
                    MsgCode[7:4] = 4'hA;
                end
                MBTRAIN:begin
                    case(i_msg_no)
                        1,3:MsgCode[3:0] = 4'h5;
                        2,4:MsgCode[3:0] = 4'hA;
                    endcase
                    MsgCode[7:4] = 4'hB;
                end
                PHYRETRAIN:begin
                    case(i_msg_no)
                        1:MsgCode[3:0] = 4'h5;
                        2:MsgCode[3:0] = 4'hA;
                    endcase
                    MsgCode[7:4] = 4'hC;
                end
                TRAINERROR:begin
                    case(i_msg_no)
                        1:MsgCode[3:0] = 4'h5;
                        2:MsgCode[3:0] = 4'hA;
                    endcase
                    MsgCode[7:4] = 4'hE;
                end
                default:MsgCode = 8'h00;
            endcase
        end
    end
end

//handling MsgInfo
always @(*) begin
    MsgInfo = 16'h0000; // default
	if(i_msg_valid) begin
		if (TX_OR_RX_INT_D_TO_C_RESULTS_RESP) begin
			MsgInfo = {{10{1'b0}}, i_msg_info[1:0], {4{1'b0}}};
		end
		else begin
			MsgInfo = {{13{1'b0}}, i_msg_info};
		end
	end
end

//output   62-bit header as cp and dp are not used here
always @(posedge i_clk or negedge i_rst_n) begin
	if (~i_rst_n) begin
        o_header_message_encoded <= 62'd0;
        o_header_done <= 1'b0;
        enable_test<=0;
  	end
    if(i_header_encoder_enable )begin
        enable_test<=1;
    end
	else if (i_msg_valid && enable_test) begin
		o_header_message_encoded [4:0] 		<= opcode;
		o_header_message_encoded [13:5] 	<= 0;
		o_header_message_encoded [21:14] 	<= MsgCode;
		o_header_message_encoded [28:22] 	<= 0;
		o_header_message_encoded [31:29] 	<= srcid;
		o_header_message_encoded [39:32] 	<= MsgSubcode;
		o_header_message_encoded [55:40] 	<= MsgInfo;
		o_header_message_encoded [58:56] 	<= dstid;
		o_header_message_encoded [61:59] 	<= 0;
		o_header_done <= 1;
        enable_test<=0;
	end
	else begin
		o_header_done <= 0;
	end
end



endmodule