module sb_controller_tx (
    input i_clk,
    input i_rst_n,
    input i_start_pattern_req,          //coming from ltsm
    input i_start_pattern_done,         //from pattern generator
    input i_msg_valid,                  //yaane 3ndy message 3yza ttb3t f mhtag a3ml encode
    input i_data_valid,                 //for messages with data{mbinit,mbtrain}htdkhlne 3la el data encoder
                                        //hatigy mn 2ay msg m3aha data lazim yb3t data_Valid 
    input i_header_done,                //gyale ml header encoder yaane el header gahz
    input i_data_done ,                 //gyale ml data encoder yaane el data gahza
    input i_packet_done,                //gyale ml packetizer yaane 7tthom f packet
    input i_SB_busy,                    //gaily mn al serializer 
    input i_msg_with_data,

    input i_iteration_finished,
    //input i_ser_done, // Serialization done signal
    input i_fifo_empty, // FIFO empty signal
    input i_fifo_full,
    // if the two high we can read 
    
    output reg o_header_encoder_enable, //ray7a ll header encoder module 
    output reg o_data_encoder_enable,   //ray7a ll data encoder module
    output reg o_frame_enable,          //ray7a ll packetizer module 
    output     o_pattern_enable,        //ray7a ll pattern encoder module 
    output reg o_sb_busy                //serializer shaghal mynf3sh haga ttb3t
);

    reg[2:0] CS,NS;
    //H3MLHOM ASSIGN BASED 3LA EL STATE EL ANA FEHA 3SHAN AZBT EL OUTPUTS
    wire encoder_header_enable, encoder_data_enable, frame_enable ; 	

    //STATES
    localparam [2:0] IDLE 					= 0;
    localparam [2:0] PATTERN_GEN 			= 1;
    localparam [2:0] START_ENCODE 		    = 2;
    localparam [2:0] START_FRAMING	 		= 3;
    localparam [2:0] FINISH			        = 4;
   

    //giving values to wires based 3la el states  
    assign encoder_header_enable  = (((CS == IDLE && NS == START_ENCODE) || (CS==PATTERN_GEN && NS == START_ENCODE)) && !i_start_pattern_req ); //1 add condition of pattern 
    // lazim i_valid_msg = 1 , i_valid_data = 1 ;
    assign encoder_data_enable    = (CS == IDLE && NS == START_ENCODE && i_data_valid && !i_start_pattern_req); // 2 add condition of pattern 
    assign frame_enable	          = (CS == START_ENCODE && NS == START_FRAMING);
    assign o_pattern_enable	      = (i_start_pattern_req)? 1 : 0; // 1 pattern  , 0 msg 
    
    //go to idle reg
    reg [1:0] idle_flag_counter;

    //////// State Memory ///////////
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            CS <= IDLE;
        end
        else begin
            CS <= NS;
        end
    end

    // Next State Logic
    always @ (*) begin
        case (CS) 
    // IDLE
            IDLE: begin
                if(i_start_pattern_req) begin 
                    NS = PATTERN_GEN;
                end
                else begin
                    if(i_msg_valid) begin
                        NS = START_ENCODE;
                    end
                    else begin
                        NS = IDLE;
                    end
                end 
            end
    // PATTERN_GEN
            PATTERN_GEN: begin
                if (i_start_pattern_done) begin
                   NS = START_ENCODE ;  
                end else begin
                    NS = PATTERN_GEN;
                end
            end
    //START_ENCODE
            START_ENCODE: begin
               if(i_header_done && (!i_data_valid || i_data_done))begin
                    NS = START_FRAMING;
               end
               else begin
                    NS = START_ENCODE;
               end
            end
    //START_FRAMING
            START_FRAMING: begin
               if(i_packet_done )begin
                NS = FINISH;
               end
               else begin
                    NS = START_FRAMING;
               end
            end
    //FINISH
            FINISH: begin // wait for 3 clk cycle 
               if(&idle_flag_counter)begin  // want another condition to return must be 2'b11
                NS = IDLE; 
               end
               else begin
                    NS = FINISH;
               end
            end
            default: NS = IDLE;
        endcase
    end
 // Output Logic 
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_header_encoder_enable<=0;
            o_data_encoder_enable<=0;
            o_frame_enable <= 0;
            
        end
        else begin
            
            if (encoder_header_enable) begin
                o_header_encoder_enable <= 1;
            end
            else begin
                o_header_encoder_enable <= 0;
            end
           

            if (encoder_data_enable) begin
                o_data_encoder_enable  <= 1; 
            end
            else begin
                o_data_encoder_enable <= 0;
            end
            

            if (frame_enable) begin
                o_frame_enable  <= 1; 
            end
            else begin
                o_frame_enable <= 0;
            end
           

        end 
    end

  //IDLE FLAG HANDLING 
always @(posedge i_clk or negedge i_rst_n) begin 
    if (~i_rst_n) begin
        idle_flag_counter <= 2'b00;
    end else if (CS == FINISH) begin //will go to finish so reset
        idle_flag_counter <= idle_flag_counter + 1;
    end else begin
        idle_flag_counter<=0;
    end
end 

// Busy is LEVEL, not pulse
always @(*) begin
    o_sb_busy =i_SB_busy;
end
endmodule:sb_controller_tx

