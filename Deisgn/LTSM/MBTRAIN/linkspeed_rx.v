module linkspeed_rx (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [3:0] i_sideband_message,
	input i_valid_tx,i_en,
	input i_point_test_ack,
	input i_sideband_valid,
	input i_valid_framing_error,i_busy_negedge_detected,
	input [15:0] i_lanes_result,
	//communicating with mbtrain controller 
    input i_first_8_tx_lanes_are_functional ,i_second_8_tx_lanes_are_functional,
    input i_comming_from_repair,
	//outputs 
	//talking with side band 
	output reg [3:0] o_sideband_message ,
	output reg o_valid_rx,
	//talknig with point test block 
	output reg o_point_test_en , o_test_ack  

);
/*------------------------------------------------------------------------------
--sideband messages  
------------------------------------------------------------------------------*/
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
/*------------------------------------------------------------------------------
--fsm states   
------------------------------------------------------------------------------*/
parameter IDLE=3'b000;
parameter WAIT_FOR_LINKSPEED_REQ=3'b001;
parameter SEND_RESPONSE_TO_LINKSPEED_REQ=3'b010;
parameter POINT_TEST=3'b011;
parameter WAIT_FOR_ANY_REQ=3'b100;
parameter WAIT_FOR_REPAIR_OR_SPEED_DEGRADE=3'b101;
parameter SEND_LAST_RESPONSE=3'b110;
parameter TEST_FINISH=3'b111;
/*------------------------------------------------------------------------------
--variables declaration  
------------------------------------------------------------------------------*/
//regs
	reg [2:0] cs,ns;
//wires 
	//sideband messages flag
	wire error_req_recieved,sb_msg_recieved,phy_retrain_req_recieved,done_req_recieved ,speed_degrade_req_recieved , repair_req_recieved;
	//lanes result flags
	wire first_8_lanes_are_functional , second_8_lanes_are_functional , repair_resource_available;
	// decisions flag 
	wire no_problem_in_tx_and_rx_lanes; // means we are going to send end response to the end request from remote link partner 
	//valid go to high conditions
	wire repair_on_first_8_lanes_is_succesful , repair_on_second_8_lanes_is_succesful;
	wire succesful_repair;
/*------------------------------------------------------------------------------
--assign statements  
------------------------------------------------------------------------------*/
//sideband messages flag
	assign error_req_recieved           = (i_sideband_message == ERROR_REQ && i_sideband_valid);
	assign phy_retrain_req_recieved     = (i_sideband_message == EXIT_TO_PHYRETRAIN_REQ && i_sideband_valid);
	assign done_req_recieved            = (i_sideband_message == DONE_REQ && i_sideband_valid);
	assign speed_degrade_req_recieved   = (i_sideband_message == EXIT_TO_SPEED_DEGRADE_REQ && i_sideband_valid);
	assign repair_req_recieved          = (i_sideband_message == EXIT_TO_REPAIR_REQ && i_sideband_valid);
//lanes flag
	assign first_8_lanes_are_functional  =  &(i_lanes_result[7 :0]) ;
	assign second_8_lanes_are_functional =  &(i_lanes_result[15:8]) ;
	assign repair_resource_available     = first_8_lanes_are_functional || second_8_lanes_are_functional ;
// decisions flag 
	assign no_problem_in_tx_and_rx_lanes = first_8_lanes_are_functional && second_8_lanes_are_functional && ~i_valid_framing_error ;
//valid conditions 
	assign repair_on_first_8_lanes_is_succesful  = i_first_8_tx_lanes_are_functional  && first_8_lanes_are_functional ;
	assign repair_on_second_8_lanes_is_succesful = i_second_8_tx_lanes_are_functional && second_8_lanes_are_functional;
	assign succesful_repair    = i_comming_from_repair && (repair_on_first_8_lanes_is_succesful || repair_on_second_8_lanes_is_succesful );
/*------------------------------------------------------------------------------
--current_state_update  
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_cs
	if(~rst_n) begin
		cs <= 0;
	end else begin
		cs <= ns;
	end
end
/*------------------------------------------------------------------------------
--next state logic   
------------------------------------------------------------------------------*/
always @(*) begin
	case (cs)
		IDLE:begin
			if (i_en) begin
				ns=WAIT_FOR_LINKSPEED_REQ;
			end else begin
				ns=IDLE;
			end
		end
		WAIT_FOR_LINKSPEED_REQ:begin
			if(i_sideband_message == START_REQ && i_sideband_valid) begin
				ns = SEND_RESPONSE_TO_LINKSPEED_REQ ;
			end else 
				ns=WAIT_FOR_LINKSPEED_REQ;
		end
		SEND_RESPONSE_TO_LINKSPEED_REQ:begin
			if (i_busy_negedge_detected && ~i_valid_tx)begin
				ns=POINT_TEST;
			end else begin
				ns=SEND_RESPONSE_TO_LINKSPEED_REQ;
			end
		end
		POINT_TEST:begin
			if(i_point_test_ack) begin
				ns=WAIT_FOR_ANY_REQ ;
			end else begin
				ns=POINT_TEST;
			end
		end
		WAIT_FOR_ANY_REQ:begin
		//detemining next state 
			if(error_req_recieved && ~i_valid_framing_error) 
				ns=WAIT_FOR_REPAIR_OR_SPEED_DEGRADE;
			else if(( error_req_recieved || phy_retrain_req_recieved || done_req_recieved ))
				ns=SEND_LAST_RESPONSE;
			else 
				ns=WAIT_FOR_ANY_REQ;
		end
		WAIT_FOR_REPAIR_OR_SPEED_DEGRADE:begin
			if(speed_degrade_req_recieved || repair_req_recieved) 
				ns=SEND_LAST_RESPONSE;
			else 
				ns=WAIT_FOR_REPAIR_OR_SPEED_DEGRADE;
		end
		SEND_LAST_RESPONSE:begin
			if (i_busy_negedge_detected && ~i_valid_tx)begin 
				ns=TEST_FINISH;	
			end else begin
				ns=SEND_LAST_RESPONSE;
			end
		end
		TEST_FINISH:begin
			if(~i_en) begin
				ns=IDLE;
			end else begin
				ns=TEST_FINISH;
			end
		end
		default : /* default */;
	endcase
end
/*------------------------------------------------------------------------------
--output logic  
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_
	if(~rst_n) begin
		o_sideband_message<=0;
	end else  begin
		case (cs)
			IDLE:begin
				o_sideband_message<=4'b0000;
				o_point_test_en<=0;
				o_test_ack <=0;
			end
			WAIT_FOR_LINKSPEED_REQ:begin
				if(ns==SEND_RESPONSE_TO_LINKSPEED_REQ) begin
					o_sideband_message<=START_RESP;
				end 
			end
			SEND_RESPONSE_TO_LINKSPEED_REQ:begin
				if(ns==POINT_TEST) begin
					o_point_test_en<=1;
				end
			end
			POINT_TEST:begin
				if(ns==WAIT_FOR_ANY_REQ) 
					o_point_test_en<=0;
			end
			WAIT_FOR_ANY_REQ:begin
					if(ns==WAIT_FOR_REPAIR_OR_SPEED_DEGRADE) begin
						o_sideband_message<=ERROR_RESP;
					end else if(ns == SEND_LAST_RESPONSE) begin
						if(phy_retrain_req_recieved) begin
							o_sideband_message <= EXIT_TO_PHYRETRAIN_RESP;
						end else if (no_problem_in_tx_and_rx_lanes || succesful_repair) begin
							o_sideband_message <= DONE_RESP;
						end else begin
							o_sideband_message<=4'b0000;
						end
					end
			end
			WAIT_FOR_REPAIR_OR_SPEED_DEGRADE:begin
				if (ns==SEND_LAST_RESPONSE) begin 
					if(speed_degrade_req_recieved) begin
						o_sideband_message<= EXIT_TO_SPEED_DEGRADE_RESP;
					end else if(repair_req_recieved && repair_resource_available) begin
						o_sideband_message <= EXIT_TO_REPAIR_RESP;
					end else begin
						o_sideband_message <= 4'b0000;
					end
				end
			end
			SEND_LAST_RESPONSE:begin
				if(ns==TEST_FINISH) begin
					o_test_ack <=1;
				end
			end
			TEST_FINISH:begin
			end
		endcase
	end
end
/*------------------------------------------------------------------------------
--valid handling   
------------------------------------------------------------------------------*/
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_valid_rx <= 1'b0;
    end else begin
       
        if ((cs==WAIT_FOR_LINKSPEED_REQ && ns == SEND_RESPONSE_TO_LINKSPEED_REQ)||
            (cs==WAIT_FOR_ANY_REQ       && ns ==WAIT_FOR_REPAIR_OR_SPEED_DEGRADE)     ||
            (cs==WAIT_FOR_ANY_REQ       && ns== SEND_LAST_RESPONSE && (phy_retrain_req_recieved || no_problem_in_tx_and_rx_lanes || succesful_repair)) ||
            (cs==WAIT_FOR_REPAIR_OR_SPEED_DEGRADE && ns == SEND_LAST_RESPONSE && ~(repair_req_recieved && ~repair_resource_available))
        )begin 
            o_valid_rx <= 1'b1;
        end else if (i_busy_negedge_detected && ~i_valid_tx) begin
            o_valid_rx <= 1'b0;
        end
    end
end
endmodule 