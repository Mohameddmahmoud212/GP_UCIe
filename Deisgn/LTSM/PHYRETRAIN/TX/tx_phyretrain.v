module tx_phyretrain #(
parameter SB_MSG_WIDTH = 4
) (
input										i_clk,
input  										i_rst_n,

input										i_PHYRETRAIN_en, 			//enable el sbinit el gyale ml ltsm
input                                       i_tx_ready_tx,          // from wrapper means that wrapper accepted my valid this cycle

input  										i_rx_msg_valid,         //rx message is valid so i should trust the input came from it
input			[SB_MSG_WIDTH-1:0]			i_decoded_SB_msg, 		// gyaly mn el SB b3d my3ml decode ll msg eli gyalo mn el partner
input                                       i_enter_from_active_or_mbtrain, //enterd phyretrain from where 
input           [1:0]                       i_link_status,  //Hshof el status w based 3leha h3ml eh 7sb el proiority el htt3ml fl akher 
input                                       i_sb_busy,      //gyale ml sb m3naha en el SB mashghola
output 	reg		[SB_MSG_WIDTH-1:0]			o_encoded_SB_msg_tx, 	// sent to SB 34an 22olo haystkhdm anhy encoding 
output reg      [2:0]                       o_msg_info,  //encoding=>bttb3t ll SB 3shan a2olo hn3ml eh:(001b:txselfcal),(100b:Repair),(010b:Speedidle)
output  reg 								o_valid_tx, 				// sent to Wrapper 34an 22olo eni 3ndi data valid 3ayz ab3tha  
output	reg									o_PHYRETRAIN_end_tx		// sent to LTSM 34an ykhls 
);

reg[1:0] CS,NS;

//H3MLHOM ASSIGN BASED 3LA EL STATE EL ANA FEHA 3SHAN AZBT EL OUTPUTS tkon pulses
wire send_phyretrain_end; 	

//STATES
localparam [1:0] IDLE           = 0;
localparam [1:0] SEND_REQ       = 1;
localparam [1:0] WAIT_FOR_RESP 	= 2;
localparam [1:0] PHYRETRAIN_END = 3;

///////////// SB messages ///////////////
localparam [SB_MSG_WIDTH-1:0] PHYRETRAIN_START_REQ  = 1;  //"PHYRETRAIN.retrain.start.req"
localparam [SB_MSG_WIDTH-1:0] PHYRETRAIN_START_RESP = 2;  //  //"PHYRETRAIN.retrain.start.rsp"


wire tx_fire = (o_valid_tx && i_tx_ready_tx); //m3naha transmitter b3t khlas f fire 3shan azbt elklam da fl wrapper

// sent once flag for the START_REQ
reg req_sent;

//WIRE M3NAH EN ETRD BL RESPOND KHLAS ANA KDA KHLST
wire got_start_resp = (i_rx_msg_valid && (i_decoded_SB_msg == PHYRETRAIN_START_RESP));

//giving values to wires based 3la el states  
assign send_phyretrain_end = (CS == WAIT_FOR_RESP && NS == PHYRETRAIN_END);

//FSM
//1 STATE MEMORY
always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        CS<=IDLE;
    end
    else begin
        CS<=NS;
    end  
end

//2 NEXT STATE LOGIC

always @(*) begin
    case(CS)

        IDLE:begin
            if(i_PHYRETRAIN_en) NS = SEND_REQ;
            else                NS = IDLE;
        end

        SEND_REQ:begin // stay here until wrapper accepts (tx_fire)
            if (!i_PHYRETRAIN_en) NS = IDLE;
            else if (tx_fire)     NS = WAIT_FOR_RESP;
            else                  NS = SEND_REQ;
        end

        WAIT_FOR_RESP:begin
            if (!i_PHYRETRAIN_en)      NS = IDLE;
            else if (got_start_resp)   NS = PHYRETRAIN_END;
            else                       NS = WAIT_FOR_RESP;
        end

        PHYRETRAIN_END:begin
            if (!i_PHYRETRAIN_en) NS = IDLE;
            else                  NS = PHYRETRAIN_END;
        end
        default:NS=IDLE;
    endcase
end

//OUTPUT LOGIC

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        o_msg_info<=0;
        o_encoded_SB_msg_tx<=0;
        //o_valid_tx<=0;
        o_PHYRETRAIN_end_tx<=0;
    end
    else begin
        o_PHYRETRAIN_end_tx<=0; //the end is a pulse same made in sbinit//
        if(!i_PHYRETRAIN_en) begin
            o_encoded_SB_msg_tx<=0;
            o_msg_info<=0;
            o_PHYRETRAIN_end_tx <=0;
        end
        if(CS == SEND_REQ) begin
            o_encoded_SB_msg_tx <= PHYRETRAIN_START_REQ; //1  //"PHYRETRAIN.retrain.start.req"
        if(i_enter_from_active_or_mbtrain==0) begin
            o_msg_info<=3'b001;//TXSELFCAL
        end
        else begin
            case(i_link_status)
                2'b01: o_msg_info <= 3'b001; // no errors -> TXSELFCAL
                2'b10: o_msg_info <= 3'b100; // repairable -> REPAIR
                2'b11: o_msg_info <= 3'b010; // not repairable -> SPEEDIDLE
                default: o_msg_info <= 3'b001;
            endcase
        end
        end
        if(send_phyretrain_end) begin
           o_PHYRETRAIN_end_tx <= 1'b1;
        end
    end
end


// Valid logic 
always @(posedge i_clk or negedge i_rst_n) begin
  if(!i_rst_n) o_valid_tx<=0;
  else if (!i_PHYRETRAIN_en || CS == IDLE || CS == PHYRETRAIN_END) begin
  o_valid_tx <= 1'b0;
end
else if (tx_fire) begin
  o_valid_tx <= 1'b0;
end
else if (CS == SEND_REQ && !req_sent && !i_sb_busy) begin
  o_valid_tx <= 1'b1;
end

end

// Track set once
always @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    req_sent <= 1'b0;
  end else begin
    if (!i_PHYRETRAIN_en || CS == IDLE || CS == PHYRETRAIN_END) begin
      req_sent <= 1'b0;
    end else if (CS == SEND_REQ && tx_fire) begin
      req_sent <= 1'b1;
    end
  end
end


endmodule
