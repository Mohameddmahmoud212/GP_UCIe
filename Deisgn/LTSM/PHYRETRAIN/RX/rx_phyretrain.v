module rx_phyretrain #(
parameter SB_MSG_WIDTH = 4
) (
input										i_clk,
input  										i_rst_n,
//from ltsm
input										i_PHYRETRAIN_en, 			//enable el sbinit el gyale ml ltsm
input                                       i_reset_resolved_state,     //trg3 el resolved state l 0 tany 3shan mtfdlsh sabta 3la haga
//from wrapper
input                                       i_tx_ready_rx,          // from wrapper means that wrapper accepted my valid this cycle
input           [2:0]                       i_local_retrain_encoding,//local yaane bt3t el die bt3ty w de el tx b3thaly hnhndlha fl wrapper
//from sb
input  										i_rx_msg_valid,         //rx message is valid so i should trust the input came from it
input			[SB_MSG_WIDTH-1:0]			i_decoded_SB_msg, 		// gyaly mn el SB b3d my3ml decode ll msg eli gyalo mn el partner w yb3tli el crossponding format liha 
input                                       i_sb_busy,              //gyale ml sb m3naha en el SB mashghola
input           [2:0]                       i_die_retrain_encoding, //gyale ml die eltanya 3n tare2 el sb w hnshof b2a 7sb de wl local_encoding eh elhyt3ml
//outputs
output 	reg		[SB_MSG_WIDTH-1:0]			o_encoded_SB_msg_rx, 	// sent to SB 34an 22olo haystkhdm anhy encoding 
output reg      [2:0]                       o_resolved_state,       // bttb3t ll ltsm 3shan y3rf hyro7 l eh w y7l elmoshkla
output  reg 								o_valid_rx, 			// sent to Wrapper 34an 22olo eni 3ndi data valid 3ayz ab3tha  
output	reg									o_PHYRETRAIN_end_rx		// sent to LTSM 34an 22olo eni khalst
);

reg[1:0] CS,NS;

//H3MLHOM ASSIGN BASED 3LA EL STATE EL ANA FEHA 3SHAN AZBT EL OUTPUTS tkon pulses
wire send_phyretrain_end; 	

//STATES
localparam [1:0] IDLE               = 0;
localparam [1:0] WAIT_FOR_REQ       = 1;
localparam [1:0] SEND_RESP 	        = 2;
localparam [1:0] PHYRETRAIN_END     = 3;

///////////// SB messages ///////////////
localparam [SB_MSG_WIDTH-1:0] PHYRETRAIN_START_REQ  = 1;  //"PHYRETRAIN.retrain.start.req"
localparam [SB_MSG_WIDTH-1:0] PHYRETRAIN_START_RESP = 2;  //  //"PHYRETRAIN.retrain.start.rsp"


wire rx_fire = (o_valid_rx && i_tx_ready_rx); //m3naha transmitter b3t khlas f fire 3shan azbt elklam da fl wrapper

// sent once flag for the START_REQ
reg resp_sent;

//WIRE M3NAH EN ETRD BL RESPOND KHLAS ANA KDA KHLST
wire got_sent_resp = (CS == SEND_RESP && rx_fire);


//giving values to wires based 3la el states  
assign send_phyretrain_end = (CS == SEND_RESP && NS == PHYRETRAIN_END);

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
            if(i_PHYRETRAIN_en) NS = WAIT_FOR_REQ;
            else                NS = IDLE;
        end

        WAIT_FOR_REQ:begin 
            if (!i_PHYRETRAIN_en) NS = IDLE;
            else if(i_decoded_SB_msg == PHYRETRAIN_START_REQ && i_rx_msg_valid ) begin    
                NS=SEND_RESP;
            end
            else NS = WAIT_FOR_REQ;
        end

        SEND_RESP:begin
            if (!i_PHYRETRAIN_en)      NS = IDLE;
            else if (got_sent_resp)   NS = PHYRETRAIN_END;
            else NS = SEND_RESP;
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
        o_encoded_SB_msg_rx<=0;
        o_PHYRETRAIN_end_rx<=0;
        o_resolved_state <= 0;
    end
    else begin
        o_PHYRETRAIN_end_rx<=0; //the end is a pulse same made in sbinit
          // if module disabled so clear everything
        if (!i_PHYRETRAIN_en) begin
            o_encoded_SB_msg_rx <= 0;
            o_resolved_state    <= 0;
        end
        if(CS==IDLE) begin
            o_encoded_SB_msg_rx<=0;
            o_PHYRETRAIN_end_rx <=0;
        end
        if(CS == WAIT_FOR_REQ && NS == SEND_RESP) begin    //IMP:m3naha en el tx b3t khlas el req// f lazm el resolved state tt3ml kda w el msg el tro7 ll sb tb2a el respond            o_encoded_SB_msg_rx<=PHYRETRAIN_START_RESP;
            case({i_local_retrain_encoding,i_die_retrain_encoding,i_rx_msg_valid})
            7'b001_001_1:o_resolved_state<=3'b001; //MBTRAIN.TXSELFCAL
            7'b001_100_1:o_resolved_state<=3'b100; //MBTRAIN.REPAIR
            7'b001_010_1:o_resolved_state<=3'b010; //MBTRAIN.SPEEDIDLE
            7'b100_001_1:o_resolved_state<=3'b100; //MBTRAIN.REPAIR
            7'b100_100_1:o_resolved_state<=3'b100; //MBTRAIN.REPAIR
            7'b100_010_1:o_resolved_state<=3'b010; //MBTRAIN.SPEEDIDLE
            7'b010_001_1:o_resolved_state<=3'b010; //MBTRAIN.SPEEDIDLE
            7'b010_100_1:o_resolved_state<=3'b010; //MBTRAIN.SPEEDIDLE
            7'b010_010_1:o_resolved_state<=3'b010; //MBTRAIN.SPEEDIDLE
            default:o_resolved_state<=0;
            endcase
        end
    
    else if(i_reset_resolved_state)  o_resolved_state<=0;
    if(send_phyretrain_end) begin
        o_PHYRETRAIN_end_rx<=1;
    end
    end
end


// VALID LOGIC
always @(posedge i_clk or negedge i_rst_n) begin
  if(!i_rst_n)  o_valid_rx<=0;
  else if (!i_PHYRETRAIN_en || CS == IDLE || CS == PHYRETRAIN_END) begin
  o_valid_rx <= 1'b0;
end
else if (rx_fire) begin
  o_valid_rx <= 1'b0;
end
else if (CS == SEND_RESP && !resp_sent && !i_sb_busy) begin
  o_valid_rx <= 1'b1;
end

end


// Track response sent once
always @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    resp_sent <= 1'b0;
  end
  else begin
    if (!i_PHYRETRAIN_en || CS == IDLE || CS == PHYRETRAIN_END) begin
      resp_sent <= 1'b0;
    end
    else if (CS == SEND_RESP && rx_fire) begin
      resp_sent <= 1'b1;
    end
  end
end





endmodule
