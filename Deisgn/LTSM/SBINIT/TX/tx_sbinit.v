    module TX_SBINIT #(
        parameter SB_MSG_WIDTH = 4
    ) (
        input										i_clk,
        input  										i_rst_n,
        input										i_SBINIT_en, 			//enable el sbinit el gyale ml ltsm
        input										i_start_pattern_done, 	//output ml sb input ll sbinit m3naha en sb b3tt el pattern khlas
        input  										i_rx_msg_valid,         //rx message is valid so i should trust the input came from it
        input 										i_sb_busy,              //m3naha en elsb busy mynf3sh ab3t 
        input                                       i_tx_ready_tx,          // from wrapper means that wrapper accepted my valid this cycle
        input			[SB_MSG_WIDTH-1:0]			i_decoded_SB_msg, 		// gyaly mn el SB b3d my3ml decode ll msg eli gyalo mn el partner w yb3tli el crossponding format liha 
        output 	reg		[SB_MSG_WIDTH-1:0]			o_encoded_SB_msg_tx, 	// sent to SB 34an 22olo haystkhdm anhy encoding 
        output	reg									o_start_pattern_req, 	// sent to SB 34an ybd2 yb3t el pattern 
        output	reg									o_SBINIT_end_tx, 		// sent to LTSM 34an ykhush el MBINIT w 22olo eni khalst
        output  reg 								o_valid_tx 				// sent to Wrapper 34an 22olo eni 3ndi data valid 3ayz ab3tha  
    );


    reg[2:0] CS,NS;

    //H3MLHOM ASSIGN BASED 3LA EL STATE EL ANA FEHA 3SHAN AZBT EL OUTPUTS
    wire send_pattern_req, send_out_of_reset, send_done_req, send_sbinit_end; 	

    //STATES
    localparam [2:0] IDLE 						= 0;
    localparam [2:0] START_SB_PATTERN 			= 1;
    localparam [2:0] SBINIT_OUT_OF_RESET 		= 2;
    localparam [2:0] WAIT_FOR_SB_BUSY	 		= 3;
    localparam [2:0] SBINIT_DONE_REQ			= 4;
    localparam [2:0] SBINIT_END					= 5;
    localparam [2:0] ERROR				        = 6;


    ///////////// SB messages ///////////////
    /////////////////////////////////////////
    localparam SBINIT_done_req_msg		= 1;
    localparam SBINIT_done_resp_msg		= 2;
    localparam SBINIT_Out_of_Reset_msg 	= 3;




    //giving values to wires based 3la el states  
    assign send_pattern_req  = (CS == IDLE && NS == START_SB_PATTERN);
    assign send_out_of_reset = (CS == SBINIT_OUT_OF_RESET);
    assign send_done_req	 = (CS == SBINIT_DONE_REQ);
    assign send_sbinit_end	 = (CS == SBINIT_DONE_REQ && NS == SBINIT_END);

    //-------------------------------
    // Option A handshake helper
    //-------------------------------
    wire tx_fire = (o_valid_tx && i_tx_ready_tx);

    // Sent once flags (so we don't keep re-sending same message)
    reg out_of_reset_sent;
    reg done_req_sent;

    //FSM 

    //1
    //////// State Memory ///////////
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            CS <= IDLE;
        end
        else begin
            CS <= NS;
        end
    end


    //2
    // Next State Logic
    always @ (*) begin
        case (CS) 
    // IDLE
            IDLE: begin
                NS = (i_SBINIT_en)? START_SB_PATTERN : IDLE;
            end
    // START_SB_PATTERN
            START_SB_PATTERN: begin
                if (i_SBINIT_en) begin
                    
                    if (i_start_pattern_done) begin 
                        NS = SBINIT_OUT_OF_RESET;
                    end 
                    else begin
                        NS = START_SB_PATTERN;
                    end
                end else begin
                    NS = IDLE;
                end
            end
    //SBINIT_OUT_OF_RESET
            SBINIT_OUT_OF_RESET: begin
                if (i_SBINIT_en) begin	
                    
                    if ((i_decoded_SB_msg == SBINIT_Out_of_Reset_msg && i_rx_msg_valid)) begin 
                        NS = WAIT_FOR_SB_BUSY;
                    end 
                    else begin
                        NS = SBINIT_OUT_OF_RESET;
                    end
                end	else begin
                    NS = IDLE;
                end	
            end
    /*-----------------------------------------------------------------------------
    * WAIT_FOR_SB_BUSY
    *-----------------------------------------------------------------------------*/
            WAIT_FOR_SB_BUSY: begin
                if (~i_SBINIT_en) begin
                    NS = IDLE;
                end 
                else if (~i_sb_busy) begin
                    NS = SBINIT_DONE_REQ;
                end else begin
                    NS = WAIT_FOR_SB_BUSY;
                end
                
            end
    /*-----------------------------------------------------------------------------
    * SBINIT_DONE_REQ
    *-----------------------------------------------------------------------------*/
            SBINIT_DONE_REQ: begin
                if (i_SBINIT_en) begin
                    
                    if (i_decoded_SB_msg == SBINIT_done_resp_msg && i_rx_msg_valid) begin 
                        NS = SBINIT_END;
                    end 
                    else begin
                        NS = SBINIT_DONE_REQ;
                    end
                end else begin
                    NS = IDLE;
                end
            end
    /*-----------------------------------------------------------------------------
    * SBINIT_END
    *-----------------------------------------------------------------------------*/
            SBINIT_END: begin
                if (!i_SBINIT_en) begin
                    NS = IDLE;
                end else begin
                    NS = SBINIT_END;
                end
            end
        endcase
    end


 // Output Logic 
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_encoded_SB_msg_tx <= 0; 
            o_start_pattern_req <= 0;
            o_SBINIT_end_tx     <= 0;
        end
        else begin
            o_start_pattern_req <= 0;
            o_SBINIT_end_tx     <= 0;

            if (CS == IDLE) begin
                o_encoded_SB_msg_tx <= 0; 
            end

            if (send_pattern_req) begin
                o_start_pattern_req <= 1;
            end

            if (send_out_of_reset) begin
                o_encoded_SB_msg_tx  <= SBINIT_Out_of_Reset_msg; 
            end

            if (send_done_req) begin
                o_encoded_SB_msg_tx  <= SBINIT_done_req_msg; 
            end

            if (send_sbinit_end) begin
                o_SBINIT_end_tx <= 1;
            end
        end 
    end


//valid logic
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_valid_tx <= 0;
    end else begin
        // Default: clear valid on fire or when not enabled/in terminal states
        if (tx_fire || !i_SBINIT_en || CS == IDLE || CS == SBINIT_END || CS == ERROR) begin
            o_valid_tx <= 0;
        end
        // Assert valid in sending states if not yet sent
        else if (CS == SBINIT_OUT_OF_RESET && !out_of_reset_sent &&!i_sb_busy) begin
            o_valid_tx <= 1;
        end
        else if (CS == SBINIT_DONE_REQ && !done_req_sent &&!i_sb_busy) begin
            o_valid_tx <= 1;
        end
        // Otherwise, keep current value (implicit hold)
    end
end


    // Track "sent once"
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            out_of_reset_sent <= 0;
            done_req_sent     <= 0;
        end else begin
            // reset flags when flow resets
            if (!i_SBINIT_en || CS == IDLE || CS == SBINIT_END || CS == ERROR) begin
                out_of_reset_sent <= 0;
                done_req_sent     <= 0;
            end else begin
                // mark as sent only when wrapper accepted (tx_fire) while in that sending state
                if (CS == SBINIT_OUT_OF_RESET && tx_fire) begin
                    out_of_reset_sent <= 1;
                end
                if (CS == SBINIT_DONE_REQ && tx_fire) begin
                    done_req_sent <= 1;
                end
            end
        end

    end


    endmodule