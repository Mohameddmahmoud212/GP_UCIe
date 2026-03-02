module RX_SBINIT #(
	parameter SB_MSG_WIDTH = 4
) (
	input										i_clk,
	input  										i_rst_n,
	input										i_SBINIT_en, 			//enable el sbinit el gyale ml ltsm
	input  										i_rx_msg_valid,         //rx message is valid so i should trust the input came from it
	input 										i_sb_busy,              //m3naha en elsb busy mynf3sh ab3t 
	input                                       i_tx_ready_rx,          // from wrapper means that wrapper accepted my valid this cycle
	input			[SB_MSG_WIDTH-1:0]			i_decoded_SB_msg, 		// gyaly mn el SB b3d my3ml decode ll msg eli gyalo mn el partner w yb3tli el crossponding format liha 
	output 	reg		[SB_MSG_WIDTH-1:0]			o_encoded_SB_msg_rx, 	// sent to SB 34an 22olo haystkhdm anhy encoding 
	output	reg									o_SBINIT_end_rx, 		// sent to LTSM 34an ykhush el MBINIT w 22olo eni khalst
	output  reg 								o_valid_rx 				// Bttb3t ll wrapper 3shan a2olo 3ny 3uz ab3t data
);

reg[2:0] CS,NS;

// STATES
localparam [2:0] IDLE 						= 0;
localparam [2:0] WAIT_FOR_DONE_REQ	 		= 1;
localparam [2:0] SBINIT_DONE_RESP			= 2;
localparam [2:0] SBINIT_END					= 3;

// SB messages
localparam SBINIT_done_req_msg		= 1;
localparam SBINIT_done_resp_msg		= 2;



//Handshake helper
wire tx_fire = (o_valid_rx && i_tx_ready_rx);   //: "RX is sending data to the wrapper"

// "Sent once" flag
reg done_resp_sent;

// FSM state memory
always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        CS <= IDLE;
    end
    else begin
        CS <= NS;
    end
end

// Next state logic
always @ (*) begin
    NS = CS;
	case (CS)

		IDLE: begin
			NS = (i_SBINIT_en)? WAIT_FOR_DONE_REQ : IDLE;
		end
		WAIT_FOR_DONE_REQ: begin
			if (!i_SBINIT_en) begin
				NS = IDLE;
			end 
			else if (i_rx_msg_valid && (i_decoded_SB_msg == SBINIT_done_req_msg)) begin
				NS = SBINIT_DONE_RESP;
			end else begin
				NS = WAIT_FOR_DONE_REQ;
			end
		end

		SBINIT_DONE_RESP: begin
			if (!i_SBINIT_en) begin
				NS = IDLE;
			end 
			else if (done_resp_sent) begin
				NS = SBINIT_END;
			end else begin
				NS = SBINIT_DONE_RESP;
			end
		end

		SBINIT_END: begin
			if (!i_SBINIT_en) begin
				NS = IDLE;
			end else begin
				NS = SBINIT_END;
			end
		end

		default: NS = IDLE;
    endcase
end

///////// Output Logic //////////
always @ (posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_encoded_SB_msg_rx <= 0;
		o_SBINIT_end_rx     <= 0;
	end
	else begin
		if (CS == IDLE) begin
			o_encoded_SB_msg_rx <= 0;
		end

		// In DONE_RESP state, present DONE_RESP encoding (must remain stable while valid=1)
		if (CS == SBINIT_DONE_RESP) begin
			o_encoded_SB_msg_rx <= SBINIT_done_resp_msg;
		end

		// End pulse when DONE_RESP is actually accepted by wrapper (tx_fire)
		if (CS == SBINIT_DONE_RESP && tx_fire) begin
			o_SBINIT_end_rx <= 1;
		end
		else begin
			o_SBINIT_end_rx <=0;

		end
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    o_valid_rx <= 1'b0;
  end else begin
    
    // assert valid only in DONE_RESP state, not yet sent, not busy
    if (i_SBINIT_en && (CS == SBINIT_DONE_RESP) &&!done_resp_sent &&!i_sb_busy) begin
      o_valid_rx <= 1'b1;
    end

    // if handshake happened, make sure we drop it
    if (tx_fire) begin
      o_valid_rx <= 1'b0;
    end
  end
end

// Track 
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		done_resp_sent <= 0;
	end else begin
		if (!i_SBINIT_en || CS == IDLE || CS == SBINIT_END || CS == ERROR) begin
			done_resp_sent <= 0;
		end else begin
			if (CS == SBINIT_DONE_RESP && tx_fire) begin
				done_resp_sent <= 1;
			end
		end
	end
end


endmodule
