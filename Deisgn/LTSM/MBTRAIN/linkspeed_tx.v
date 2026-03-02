module linkspeed_tx (
    input clk,    // Clock
    input rst_n,  // Asynchronous reset active low
    input [3:0] i_sideband_message,
    
    input i_valid_rx,i_en , i_point_test_ack , i_busy_negedge_detected, i_valid_framing_error , //come from the checker ,
    input [15:0]i_lanes_result , //come from the repair(your local RX compare results / error flags per lane),
	input i_sideband_valid,
    //inputs 
    //communicating with mbtrain controller 
    input i_first_8_tx_lanes_are_functional ,i_second_8_tx_lanes_are_functional,//(your local lane-health summary from REPAIR / lane manager)
    input i_comming_from_repair,
    // Outputs 
    // Talking with sideband 
    output reg [3:0] o_sideband_message,
    output reg o_valid_tx,
    // Talking with LTSM
    output reg o_test_ack, 
    output reg o_phy_retrain_req,o_error_req, //sent or received 
    output reg o_speed_degrade_req,           //sent or received
    output reg o_repair_req ,                 //sent or received
    //talking with phyretrain (new)
	output reg [1:0] o_phyretrain_error_encoding,
	//talking with mbtrain controller
	output reg o_local_first_8_lanes_are_functional ,o_local_second_8_lanes_are_functional ,//calculating of the result of my lanes 
	//talking with point test block 
	output reg  o_point_test_en
);

    /*--------------------------------------------------------------------------
    -- Sideband codes (PLACEHOLDERS for 4-bit world)
    -- Reuse handshake style like other blocks:
    -- 0001 START_REQ, 0010 START_RSP, 0011 END_REQ, 0100 END_RSP
    --------------------------------------------------------------------------*/
    localparam START_REQ=4'b0001;
    localparam START_RESP=4'b0010;
    localparam ERROR_REQ=4'b0011;
    localparam ERROR_RESP=4'b0100;
    localparam EXIT_TO_REPAIR_REQ=4'b0101;
    localparam EXIT_TO_REPAIR_RESP=4'b0110;
    localparam EXIT_TO_SPEED_DEGRADE_REQ=4'b0111;
    localparam EXIT_TO_SPEED_DEGRADE_RESP=4'b1000;
    localparam DONE_REQ=4'b1001;
    localparam DONE_RESP=4'b1010;
    localparam EXIT_TO_PHYRETRAIN_REQ=4'b1011;
    localparam EXIT_TO_PHYRETRAIN_RESP=4'b1100;

    // PLACEHOLDER “event” messages observed during linkspeed (edit as per your standard mapping)
    parameter IDLE = 0;
    parameter LINK_SPEED_REQ = 1;
    parameter POINT_TEST = 2;
    parameter RESULT_ANALYSIS = 3;
    parameter PHY_RETRAIN_REQ = 4;
    parameter END_REQ = 5;
    parameter ERROR_REQ_ST= 6;
    parameter TEST_FINISHED = 7;
    parameter REPAIR_REQ = 8;
    parameter SPEED_DEGRADE_REQ = 9;
    /*--------------------------------------------------------------------------
    -- FSM states
    --------------------------------------------------------------------------*/
    wire first_8_lanes_are_functional ,second_8_lanes_are_functional ;
    wire  repair_on_first_8_lanes_is_succesful ,repair_on_second_8_lanes_is_succesful;
    wire succesful_repair  ;

    reg [2:0] cs, ns;
    assign first_8_lanes_are_functional = & (i_lanes_result[7:0]) ;
    assign second_8_lanes_are_functional = &(i_lanes_result[15:8]);
    //valid conditions 
    
    //handling the case in which we are coming from repair to link speed so if we don't have the 16 lanes are functional 
    // we shouldn't go to the error state but we have to check if we have any 8 lanes that are functional 
    // and if any 8 are functional we should go to end requeset
    assign repair_on_first_8_lanes_is_succesful  = i_first_8_tx_lanes_are_functional  && first_8_lanes_are_functional ;
    assign repair_on_second_8_lanes_is_succesful = i_second_8_tx_lanes_are_functional && second_8_lanes_are_functional;
    assign succesful_repair= i_comming_from_repair && (repair_on_first_8_lanes_is_succesful || repair_on_second_8_lanes_is_succesful );

    // state update
    always @(posedge clk or negedge  rst_n) begin
        if (!rst_n) cs <= IDLE;
        else        cs <= ns;
    end

    // next-state logic
    always @(*) begin
    case (cs)
        IDLE:begin
        	if(i_en)begin
        		ns=LINK_SPEED_REQ;
        	end else begin
        		ns=IDLE;
        	end
		end
		LINK_SPEED_REQ:begin
			if (~i_en) ns = IDLE;
            else if(i_sideband_message==START_RESP && i_sideband_valid)  begin
					ns=POINT_TEST;
				end else begin
					ns=LINK_SPEED_REQ;
				end
			
		end
		POINT_TEST:begin
			if (~i_en) ns = IDLE;
            else if(i_point_test_ack) begin
                ns=RESULT_ANALYSIS;
            end else begin
                ns=POINT_TEST;
            end
		end
		RESULT_ANALYSIS:begin
			if (~i_en) ns = IDLE;
			else if(i_valid_framing_error) begin
					ns=PHY_RETRAIN_REQ;
				end else if (succesful_repair) begin
					ns=END_REQ;
				end else if (~first_8_lanes_are_functional || ~second_8_lanes_are_functional )  begin
					ns=ERROR_REQ_ST;
				end else 
					ns=END_REQ;
                end 
		PHY_RETRAIN_REQ:begin
			if (~i_en) ns = IDLE;
			else if(i_sideband_message == EXIT_TO_PHYRETRAIN_RESP && i_sideband_valid) 
					ns=TEST_FINISHED;
				else 
					ns=PHY_RETRAIN_REQ;
		end
		END_REQ:begin
			if (~i_en) ns = IDLE;
			else if((i_sideband_message == DONE_RESP && i_sideband_valid) || o_sideband_message==4'b0000 ) begin
					ns=TEST_FINISHED;
				end else begin
					ns=END_REQ;
				end
		end
		ERROR_REQ_ST:begin
			if (~i_en) ns = IDLE;
			else if(o_phy_retrain_req) begin
					ns=TEST_FINISHED;
				end else if(i_sideband_message == ERROR_RESP && i_sideband_valid) begin
					if(second_8_lanes_are_functional || first_8_lanes_are_functional) begin
						ns=REPAIR_REQ;
					end else begin
						ns=SPEED_DEGRADE_REQ;
					end
				end else begin
					ns=ERROR_REQ_ST;
				end
		end
		REPAIR_REQ:begin
			if (~i_en) ns = IDLE;
			else if(o_phy_retrain_req || o_speed_degrade_req || i_sideband_message == EXIT_TO_REPAIR_RESP) begin
					ns=TEST_FINISHED;
				end else begin
					ns=REPAIR_REQ;
				end
		end
		SPEED_DEGRADE_REQ:begin
			if (~i_en) ns = IDLE;
			else if(o_phy_retrain_req || i_sideband_message == EXIT_TO_SPEED_DEGRADE_RESP) begin
					ns=TEST_FINISHED;
				end else begin
					ns=SPEED_DEGRADE_REQ;
				end
		end
		TEST_FINISHED:begin
			if(~i_en) begin
				ns=IDLE;
			end else begin
				ns=TEST_FINISHED;
			end
		end
        default: ns = cs;
    endcase
end
/*------------------------------------------------------------------------------
-- Output Logic  
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_output
    if (~rst_n) begin
        o_sideband_message <= 0;
        o_test_ack <= 0;
        
        o_point_test_en<=1'b0;
        o_phyretrain_error_encoding<=0;
        o_local_first_8_lanes_are_functional<=0;
        o_local_second_8_lanes_are_functional<=0;
    end else begin
        case (cs)
            IDLE:begin //done
        		o_sideband_message <= 0;
        		o_test_ack <= 0;
        		o_point_test_en<=1'b0; //was made one but there was no reason for it 
        		
        		if(ns==LINK_SPEED_REQ)
					o_sideband_message<= START_REQ;
			end
			LINK_SPEED_REQ:begin //done
				if(ns==POINT_TEST)  begin
					o_point_test_en<=1'b1;
				end
			end
			POINT_TEST:begin //done
				if(ns==RESULT_ANALYSIS) 
					o_point_test_en<=1'b0;
			end
			RESULT_ANALYSIS:begin
				// lanes result 
					o_local_first_8_lanes_are_functional <=first_8_lanes_are_functional;
					o_local_second_8_lanes_are_functional<=second_8_lanes_are_functional;
				//phyretrain error encoding
					if(first_8_lanes_are_functional && second_8_lanes_are_functional) begin
						o_phyretrain_error_encoding<=2'b01;
					end else if (first_8_lanes_are_functional || second_8_lanes_are_functional ) begin
						o_phyretrain_error_encoding<=2'b10;
					end else begin 
						o_phyretrain_error_encoding<=2'b11;
					end
				//determinig next sideband message 
					if(ns==PHY_RETRAIN_REQ) begin //done
						o_sideband_message<= EXIT_TO_PHYRETRAIN_REQ;
					// missed from the next condituion 	
					end else if(ns == ERROR_REQ_ST && ~o_phy_retrain_req) begin
						o_sideband_message <= ERROR_REQ;
					end else if (ns == END_REQ && ~o_phy_retrain_req && ~ o_error_req)
					// end else if (ns == END_REQ )
						o_sideband_message<=DONE_REQ;
					else begin
						o_sideband_message<=4'b0000;
					end
			end
			PHY_RETRAIN_REQ:begin //done
				// Add output logic here
			end
			END_REQ:begin
					if(o_phy_retrain_req || o_speed_degrade_req || o_repair_req) begin
						
						o_sideband_message<=4'b0000;
						
					end
			end
			ERROR_REQ_ST:begin
					if(ns==TEST_FINISHED) begin
						
						o_sideband_message<=4'b0000;
						
					end else if(ns==REPAIR_REQ) begin
						o_sideband_message<=EXIT_TO_REPAIR_REQ;
					end else if (ns==SPEED_DEGRADE_REQ) begin
						o_sideband_message<= EXIT_TO_SPEED_DEGRADE_REQ;
						o_local_first_8_lanes_are_functional <=i_first_8_tx_lanes_are_functional;
						o_local_second_8_lanes_are_functional<=i_second_8_tx_lanes_are_functional;
					end
			end
			REPAIR_REQ:begin
					if(o_phy_retrain_req || o_speed_degrade_req) begin
						o_sideband_message<=4'b0000;
						
					end
			end
			SPEED_DEGRADE_REQ:begin
					if(o_phy_retrain_req) begin
						o_sideband_message<=4'b0000;
						
					end
			end
			TEST_FINISHED:begin //done
				o_test_ack<=1'b1;
			end
            default: /* default */;
        endcase
    end
end

/*------------------------------------------------------------------------------
--output flags   
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin 
	if(!rst_n ) begin
		o_phy_retrain_req <= 0;
	end else if (cs == IDLE)begin
		o_phy_retrain_req <= 0;		
	end else if( (i_sideband_message == EXIT_TO_PHYRETRAIN_REQ || o_sideband_message == EXIT_TO_PHYRETRAIN_REQ ) && cs!=POINT_TEST) begin
		o_phy_retrain_req <= 1;
	end
end
always @(posedge clk or negedge rst_n) begin 
	if(!rst_n ) begin
		o_error_req <= 0;
	end else if (cs == IDLE)begin
		o_error_req <= 0;		
	end else if( (i_sideband_message == ERROR_REQ || o_sideband_message == ERROR_REQ ) && cs!=POINT_TEST) begin
		o_error_req <=  1;
	end
end
always @(posedge clk or negedge rst_n) begin 
	if(!rst_n ) begin
		o_repair_req <= 0;
	end else if (cs == IDLE)begin
		o_repair_req <= 0;		
	end else if( (i_sideband_message == EXIT_TO_REPAIR_REQ || o_sideband_message == EXIT_TO_REPAIR_REQ ) && cs!=POINT_TEST) begin
		o_repair_req <= 1;
	end
end
always @(posedge clk or negedge rst_n) begin 
	if(!rst_n ) begin
		o_speed_degrade_req <= 0;
	end else if (cs == IDLE)begin
		o_speed_degrade_req <= 0;		
	end else if( (i_sideband_message == EXIT_TO_SPEED_DEGRADE_REQ || o_sideband_message == EXIT_TO_SPEED_DEGRADE_REQ ) && cs!=POINT_TEST) begin
		o_speed_degrade_req <= 1;
	end
end
    
/*--------------- ---------------------------------------------------------------
--handling valid   
------------------------------------------------------------------------------*/
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_tx <= 1'b0;
        end else if ((cs == IDLE && ns == LINK_SPEED_REQ) || (cs == RESULT_ANALYSIS && ns == PHY_RETRAIN_REQ)
                    || (cs == RESULT_ANALYSIS && (ns == ERROR_REQ_ST && ~o_phy_retrain_req)) 
                    || (cs == RESULT_ANALYSIS && (ns == END_REQ && ~o_phy_retrain_req && ~ o_error_req)) 
                    || (cs== ERROR_REQ_ST   && (ns==REPAIR_REQ || ns==SPEED_DEGRADE_REQ)) ) begin

            o_valid_tx <= 1'b1;
        end else if (i_busy_negedge_detected && ~i_valid_rx) begin
            o_valid_tx <= 1'b0;
        end
    end
endmodule 