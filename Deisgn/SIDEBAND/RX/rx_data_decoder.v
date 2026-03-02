module SB_DATA_DECODER_MIN16 (
    input  wire        i_clk,
    input  wire        i_rst_n,

    // Valid when header + payload are stable for this cycle
    input  wire        i_pkt_valid,

    // Decoded header fields (from packet framing block)
    input  wire [7:0]  i_msgcode,
    input  wire [7:0]  i_msgsubcode,

    // DataField[63:0]
    input  wire [63:0] i_datafield,
    
    // -------------------------------------------------------------------------
    // Output: single 16-bit decoded data + classification
    // -------------------------------------------------------------------------
    output reg  [15:0] o_data16,
    output reg   o_data16_valid,
    output reg o_data_decoder_done//added


    // Kind indicates what o_data16 represents
    // 0 = none/unknown
    // 1 = TEST (start request)  -> o_data16 = DataField[15:0] (config low-word)
    // 2 = PARAM                 -> o_data16 = {5'b0, DataField[10:0]}
    // 3 = REVERSAL              -> o_data16 = DataField[15:0]
    //output reg  [2:0]  //o_kind // optional output 
);

    // -------------------------
    // Message codes (from your code)
    // -------------------------
    localparam [7:0] MSGCODE_TEST_START_REQ = 8'h85;

    // From your table screenshot:
    // - Start Tx Init D->C eye sweep req:  85h / 05h
    // - Start Rx Init D->C point test req: 85h / 07h
    localparam [7:0] SUB_START_EYE_SWEEP   = 8'h05;
    localparam [7:0] SUB_START_POINT_TEST  = 8'h07;

    localparam [7:0] MSGCODE_PARAM   = 8'h00; 
    localparam [7:0] SUBCODE_PARAM   = 8'h00; 

    localparam [7:0] MSGCODE_REVERSAL = 8'h00; 
    localparam [7:0] SUBCODE_REVERSAL = 8'h00; 
   

    wire is_test_eye_sweep;
    assign is_test_eye_sweep = (i_msgcode == MSGCODE_TEST_START_REQ) && (i_msgsubcode == SUB_START_EYE_SWEEP);

        
    wire is_test_point ;
    assign is_test_point = (i_msgcode == MSGCODE_TEST_START_REQ) && (i_msgsubcode == SUB_START_POINT_TEST);
        

    wire is_param;
    assign is_param = ((i_msgcode == 8'hAA)|| (i_msgcode == 8'hAA)) && (i_msgsubcode == 8'h00);

    wire is_reversal;
    assign is_reversal = (i_msgcode == 8'hAA ) && (i_msgsubcode == 8'h0F);

    // -------------------------
    // Register outputs (clean timing)
    // -------------------------
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_data16       <= 16'h0000;
            o_data16_valid <= 1'b0;
            o_data_decoder_done<=0;
            //o_kind         <= 3'd0;

        end else begin
            // defaults each cycle
            o_data16       <= 16'h0000;
            o_data16_valid <= 1'b0;
            o_data_decoder_done<=0;
           // //o_kind         <= 3'd0;

            if (i_pkt_valid) begin
                if (is_test_eye_sweep || is_test_point) begin//updated after complet the test blocks 
                    o_data16       <= i_datafield[15:0];
                    o_data16_valid <= 1'b1;
                    o_data_decoder_done<=1;
                  //  //o_kind         <= 3'd1;
                end

                else if (is_param) begin
                    o_data16       <= {5'b0, i_datafield[10:0]};
                    o_data16_valid <= 1'b1;
                    o_data_decoder_done<=1;
                   /// //o_kind         <= 3'd2;
                end

                else if (is_reversal) begin
                    o_data16       <= i_datafield[15:0];
                    o_data16_valid <= 1'b1;
                    o_data_decoder_done<=1;
                    ////o_kind         <= 3'd3;
                end

            end
        end
    end

endmodule
