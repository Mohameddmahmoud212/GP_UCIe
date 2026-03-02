//==============================================================
// RX SIDE
//==============================================================
module RX_TRAINERROR_HS #(
    parameter SB_MSG_WIDTH = 4
)(
    input                                   i_clk,              // System clock
    input                                   i_rst_n,            // Active low reset

    input                                   i_trainerror_en,    // From LTSM

    input                                   i_rx_msg_valid,     // From SB decoder
    input  [SB_MSG_WIDTH-1:0]               i_decoded_SB_msg,   // From SB decoder

    output reg [SB_MSG_WIDTH-1:0]           o_encoded_SB_msg_rx,// To SB encoder
    output reg                              o_valid_rx,         // To wrapper
    output reg                              o_trainerror_end_rx // To LTSM
);

    //----------------------------------------------------------
    // Messages
    //----------------------------------------------------------
    localparam TRAINERROR_REQ  = 4'd15;
    localparam TRAINERROR_RESP = 4'd14;

    //----------------------------------------------------------
    // FSM States
    //----------------------------------------------------------
    localparam IDLE      = 2'd0;
    localparam WAIT_REQ  = 2'd1;
    localparam SEND_RESP = 2'd2;
    localparam DONE      = 2'd3;

    reg [1:0] CS, NS;

    //----------------------------------------------------------
    // State register
    //----------------------------------------------------------
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            CS <= IDLE;
        else
            CS <= NS;
    end

    //----------------------------------------------------------
    // Next state logic
    //----------------------------------------------------------
   always @(*) begin
    case (CS)

        IDLE:
            NS = (i_trainerror_en) ? WAIT_REQ : IDLE;

        WAIT_REQ:
            if (i_rx_msg_valid && i_decoded_SB_msg == TRAINERROR_REQ)
                NS = SEND_RESP;
            else if (i_rx_msg_valid && i_decoded_SB_msg == TRAINERROR_RESP)
                NS = DONE;
            else
                NS = WAIT_REQ;

        SEND_RESP:
            NS = DONE;

        DONE:
            NS = (!i_trainerror_en) ? IDLE : DONE;

        default:
            NS = IDLE;
    endcase
end
    //----------------------------------------------------------
    // Output logic
    //----------------------------------------------------------
 always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_encoded_SB_msg_rx <= 0;
        o_valid_rx          <= 0;
        o_trainerror_end_rx  <= 0;
    end
    else begin
        // default clears (important!)
        o_valid_rx          <= 0;
        o_trainerror_end_rx  <= 0;

        case (CS)

            IDLE: begin
                o_encoded_SB_msg_rx <= 0;
            end

            WAIT_REQ: begin
                // waiting for request
            end

            SEND_RESP: begin
                o_encoded_SB_msg_rx <= TRAINERROR_RESP;
                o_valid_rx          <= 1;
            end

            DONE: begin
                o_trainerror_end_rx  <= 1;
            end

        endcase
    end
end

endmodule