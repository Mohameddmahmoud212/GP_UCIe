module sb_rx_controller (
    input         i_clk,
    input         i_rst_n,
    input         i_header_decoder_done,           //gyale ml header decoder yaane el header gahz
    input         i_data_decoder_done ,            //gyale ml data decoder yaane el data gahza
    input [63:0]  i_deser_data,                    // data from deserializer
    input         i_data_valid,                     // data is valid

    input         i_deser_done,                    // deserialization done signal
    //input         i_pattern_decetded_done,         //coming from pattern detection htkon output hnakk
    output reg    o_header_decoder_enable,          //ray7a ll header decoder module 
    output reg    o_data_decoder_enable,            //ray7a ll data decoder module
    output reg    o_msg_valid_rx,                   // message valid to ltsm or **
    //output reg    o_sb_start_pattern_detect_rx,     // start pattern detection 
    output reg    o_sb_pattern_detect_done_rx       // pattern is detected

);

    reg[2:0] CS,NS;	
    //STATES
    localparam [2:0] IDLE 					= 0;
    //localparam [2:0] PATTERN_DETECT 		= 1;
    localparam [2:0] HEADER_DECODE	 		= 1;
    localparam [2:0] DATA_DECODE            = 2;
    localparam [2:0] GENERAL_DECODE 	    = 3;
    localparam [2:0] BAD_PACKET 	        = 4;


    wire [4:0] opcode;
    wire [7:0] MsgSubCode;
    wire [7:0] MsgCode;
    wire [15:0]MsgInfo;
    wire [2:0] dstid;


    assign opcode     = i_deser_data[4:0];
    assign MsgSubCode = i_deser_data[39:32];
    assign MsgCode    = i_deser_data[21:14];
    assign MsgInfo    = i_deser_data[55:40];
    assign dstid      = i_deser_data[58:56];  //WILL NOT BE USED NOW


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
    // IDLE  CORRECT
            IDLE: begin
                if(~i_rst_n)begin
                    NS = IDLE;
                end
                else begin
                    if(i_deser_done && correct_pattern(i_deser_data)) begin //0
                        NS = HEADER_DECODE;
                    end
                    else begin
                        NS = IDLE;
                    end
                end
            end  //ehna hena frden en awl haga ml ltsm gyale hya el sbinit f lazm abd2 bl pattern
    // PATTERN_DETECT   
            /*
             PATTERN_DETECT: begin
                if(~i_rst_n)begin
                    NS = IDLE;
                end
                else begin                   
                    if(i_header_decoder_done)begin
                        NS = HEADER_DECODE;
                    end
                    else begin
                        NS = PATTERN_DETECT;  //changed from ns  = idle
                    end
                end
            end
            */
           
    //HEADER_DECODE
            HEADER_DECODE: begin
                if (!i_rst_n) begin
                    NS = IDLE;
                end
                else begin
                    if(i_data_valid && i_header_decoder_done)begin
                        NS = DATA_DECODE;
                    end
                    else begin
                        if(i_header_decoder_done) begin //no dataaaa bs de m7taga ttzbt hnroh ll finish leh tb lw 3yz ab3t data tany aw encode tany???
                            NS = GENERAL_DECODE;
                        end
                        else begin
                            NS = HEADER_DECODE;
                        end
                    end
               end
            end
    //START_FRAMING
            DATA_DECODE: begin
              if (!i_rst_n) begin
                    NS = IDLE;
                end
                else begin
                    if(i_data_decoder_done)begin
                            NS = GENERAL_DECODE;
                    end
                    else begin
                       NS = DATA_DECODE;
                    end
               end
            end 
    //GENERAL_DECODE
            GENERAL_DECODE: begin  
                if (!i_rst_n) begin
                    NS = IDLE;
                end
                else if(i_header_decoder_done && i_deser_done)begin
                    NS = HEADER_DECODE;
                end
                else begin
                    NS = GENERAL_DECODE;
                end
            end
            default: NS = IDLE;
        endcase
    end
 
    // Output Logic 
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_header_decoder_enable<=0;
            o_data_decoder_enable<=0;
            o_msg_valid_rx <= 0;
            //o_sb_start_pattern_detect_rx<=0;
            o_sb_pattern_detect_done_rx<=0;
        end
        else begin

            if ((CS == IDLE && NS == HEADER_DECODE) || (CS == GENERAL_DECODE  && NS == HEADER_DECODE)) begin
                o_sb_pattern_detect_done_rx<= 1; 
                o_header_decoder_enable<=1;
                o_msg_valid_rx<=1;
                o_data_decoder_enable<=0;
            end

            else if (CS == HEADER_DECODE && NS == DATA_DECODE && i_data_valid) begin
                o_data_decoder_enable<=1;
                o_msg_valid_rx<=1;
                o_header_decoder_enable<=0;
            end
            else begin
                 o_sb_pattern_detect_done_rx<= 0; 
                o_header_decoder_enable<=0;
                o_msg_valid_rx<=0;
                o_data_decoder_enable<=0;
            end

        end 
    end



function automatic correct_pattern (input [63:0] data);
  integer i;
  begin
    correct_pattern = (data[63] == 1'b1);
    for (i = 0; i < 62; i = i + 1) begin
      if (data[i] != data[i+2]) correct_pattern = 1'b0;
    end
  end
endfunction

endmodule

