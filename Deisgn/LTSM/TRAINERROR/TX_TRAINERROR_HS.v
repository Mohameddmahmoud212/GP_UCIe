module TX_TRAINERROR_HS #(
    parameter SB_MSG_WIDTH = 4
)(
    //=====================================================
    // Clock & Reset
    //=====================================================

    input                                   i_clk,     
    // From: Top system clock
    // Used by: All sequential logic in this module

    input                                   i_rst_n,   
    // From: Global reset controller
    // Active low reset for FSM and outputs


    //=====================================================
    // Control From LTSM
    //=====================================================

    input                                   i_trainerror_en,  
    // From: LTSM
    // Meaning: Enable TRAINERROR handshake phase
    // When asserted → this TX block starts handshake


    //=====================================================
    // Inputs From Sideband (SB) Decoder
    //=====================================================

    input                                   i_rx_msg_valid,  
    // From: Sideband block (SB)
    // Meaning: Indicates a decoded message from remote die is valid

    input  [SB_MSG_WIDTH-1:0]               i_decoded_SB_msg,
    // From: SB decoder
    // Meaning: Decoded message received from remote partner


    //=====================================================
    // Outputs To Sideband (SB) Encoder
    //=====================================================

    output reg [SB_MSG_WIDTH-1:0]           o_encoded_SB_msg_tx,
    // To: SB encoder
    // Meaning: Message to transmit to remote die


    output reg                              o_valid_tx,
    // To: Wrapper
    // Meaning: This TX block has a valid message to send
    // Wrapper uses it for sideband arbitration


    //=====================================================
    // Output To LTSM
    //=====================================================

    output reg                              o_trainerror_end_tx
    // To: LTSM
    // Meaning: TX side of TRAINERROR handshake completed
    // Combined with RX done using AND logic
);

/////////////////////////////////////////
//////////// Internal signals ///////////
/////////////////////////////////////////

reg [2:0] CS, NS;

/////////////////////////////////////////
//////////// Machine STATES /////////////
/////////////////////////////////////////

localparam [2:0] IDLE                  = 0;
localparam [2:0] SEND_TRAINERROR_REQ   = 1;
localparam [2:0] WAIT_FOR_RESP         = 2;
localparam [2:0] TEST_FINISHED         = 3;

/////////////////////////////////////////
///////////// SB messages ///////////////
/////////////////////////////////////////

localparam TRAINERROR_entry_req_msg  = 4'd15;
localparam TRAINERROR_entry_resp_msg = 4'd14;

/////////////////////////////////
//////// State Memory ///////////
/////////////////////////////////

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end

/////////////////////////////////
/////// Next State Logic ////////
/////////////////////////////////

always @(*) begin
    case (CS)

        IDLE: begin
            if (i_trainerror_en)
                NS = SEND_TRAINERROR_REQ;
            else
                NS = IDLE;
        end

        SEND_TRAINERROR_REQ: begin
            NS = WAIT_FOR_RESP;
        end

        WAIT_FOR_RESP: begin
            if (i_rx_msg_valid &&
                i_decoded_SB_msg == TRAINERROR_entry_resp_msg)
                NS = TEST_FINISHED;
            else
                NS = WAIT_FOR_RESP;
        end

        TEST_FINISHED: begin
            if (!i_trainerror_en)
                NS = IDLE;
            else
                NS = TEST_FINISHED;
        end

        default: NS = IDLE;
    endcase
end

/////////////////////////////////
///////// Output Logic //////////
/////////////////////////////////

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_encoded_SB_msg_tx  <= 0;
        o_valid_tx           <= 0;
        o_trainerror_end_tx   <= 0;
    end
    else begin
        // default safe clears
        o_valid_tx          <= 0;
        o_trainerror_end_tx   <= 0;

        case (CS)

            IDLE: begin
                o_encoded_SB_msg_tx <= 0;
            end

            SEND_TRAINERROR_REQ: begin
                o_encoded_SB_msg_tx <= TRAINERROR_entry_req_msg;
                o_valid_tx          <= 1;
            end

            WAIT_FOR_RESP: begin
                // no outputs, waiting
            end

            TEST_FINISHED: begin
                o_trainerror_end_tx  <= 1;
            end

        endcase
    end
end

endmodule