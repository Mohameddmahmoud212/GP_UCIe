
// Description:
// RX-side FSM for MBINIT.REPAIRVAL.
// This module reacts to TX sideband requests, returns logged VAL detection
// results, and completes the REPAIRVAL handshake.

////////////////////////////////////////////////////////////////////////////////

module REPAIRVAL_ModulePartner (
    input  wire        CLK,
    input  wire        rst_n,

    // Control
    input  wire        i_REPAIRCLK_end,        // Enter REPAIRVAL only after REPAIRCLK ends

    // Sideband interface
    input  wire [3:0]  i_Rx_SbMessage,         // Incoming SB message from TX
    input  wire        i_msg_valid,             // SB message valid
    input  wire        i_Busy_SideBand,         // SB busy indicator
    input  wire        i_falling_edge_busy,     // Indicates SB transaction completed

    // Detection result (abstracted)
    input  wire        i_VAL_Result_logged,     // Logged VAL detection result

    // Outputs
    output reg         o_VAL_Result_logged,     // Result returned to TX
    output reg [3:0]   o_TX_SbMessage,           // SB response message
    output reg         o_ValidOutDatat_ModulePartner,
    output reg         o_MBINIT_REPAIRVAL_ModulePartner_end,
    output reg         o_enable_cons             // Local enable / debug hook
);

////////////////////////////////////////////////////////////////////////////////
// Sideband message encodings
////////////////////////////////////////////////////////////////////////////////
localparam MBINI_REPAIRVAL_init_req     = 4'b0001;
localparam MBINIT_REPAIRVAL_init_resp   = 4'b0010;
localparam MBINIT_REPAIRVAL_result_req  = 4'b0011;
localparam MBINIT_REPAIRVAL_result_resp = 4'b0100;
localparam MBINIT_REPAIRVAL_done_req    = 4'b0101;
localparam MBINIT_REPAIRVAL_done_resp   = 4'b0110;

////////////////////////////////////////////////////////////////////////////////
// FSM state definitions
////////////////////////////////////////////////////////////////////////////////
localparam IDLE                        = 4'd0;
localparam CHECK_INIT_REQ              = 4'd1;
localparam CHECK_BUSY_INIT             = 4'd2;
localparam INIT_RESP                   = 4'd3;
localparam HANDLE_VALID                = 4'd4;
localparam CHECK_BUSY_RESULT           = 4'd5;
localparam RESULT_RESP                 = 4'd6;
localparam CHECK_BUSY_DONE             = 4'd7;
localparam DONE_RESP                   = 4'd8;
localparam DONE                        = 4'd9;

reg [3:0] CS, NS;

////////////////////////////////////////////////////////////////////////////////
// State register
////////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end

////////////////////////////////////////////////////////////////////////////////
// Next-state logic
////////////////////////////////////////////////////////////////////////////////
always @(*) begin
    NS = CS;

    case (CS)

        // --------------------------------------------------
        // Wait for REPAIRVAL phase to become active
        // --------------------------------------------------
        IDLE: begin
            if (i_REPAIRCLK_end)
                NS = CHECK_INIT_REQ;
        end

        // --------------------------------------------------
        // Wait for INIT request from TX
        // --------------------------------------------------
        CHECK_INIT_REQ: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_msg_valid && i_Rx_SbMessage == MBINI_REPAIRVAL_init_req)
                NS = CHECK_BUSY_INIT;
        end

        // --------------------------------------------------
        // Ensure sideband is free before responding
        // --------------------------------------------------
        CHECK_BUSY_INIT: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (!i_Busy_SideBand)
                NS = INIT_RESP;
        end

        // --------------------------------------------------
        // Send INIT response to TX
        // --------------------------------------------------
        INIT_RESP: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_falling_edge_busy)
                NS = HANDLE_VALID;
        end

        // --------------------------------------------------
        // Central receive/dispatch state
        // --------------------------------------------------
        HANDLE_VALID: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REPAIRVAL_result_req)
                NS = CHECK_BUSY_RESULT;
            else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REPAIRVAL_done_req)
                NS = CHECK_BUSY_DONE;
        end

        // --------------------------------------------------
        // Prepare RESULT response
        // --------------------------------------------------
        CHECK_BUSY_RESULT: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (!i_Busy_SideBand)
                NS = RESULT_RESP;
        end

        // --------------------------------------------------
        // Send RESULT response
        // --------------------------------------------------
        RESULT_RESP: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_falling_edge_busy)
                NS = HANDLE_VALID;
        end

        // --------------------------------------------------
        // Prepare DONE response
        // --------------------------------------------------
        CHECK_BUSY_DONE: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (!i_Busy_SideBand)
                NS = DONE_RESP;
        end

        // --------------------------------------------------
        // Send DONE response
        // --------------------------------------------------
        DONE_RESP: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_falling_edge_busy)
                NS = DONE;
        end

        // --------------------------------------------------
        // Terminal state
        // --------------------------------------------------
        DONE: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
        end

        default: NS = IDLE;
    endcase
end

////////////////////////////////////////////////////////////////////////////////
// Output logic (registered)
////////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) begin
        o_TX_SbMessage                      <= 4'b0000;
        o_ValidOutDatat_ModulePartner       <= 1'b0;
        o_MBINIT_REPAIRVAL_ModulePartner_end<= 1'b0;
        o_VAL_Result_logged                 <= 1'b0;
        o_enable_cons                       <= 1'b0;
    end else begin
        // Defaults
        o_TX_SbMessage                      <= 4'b0000;
        o_ValidOutDatat_ModulePartner       <= 1'b0;
        o_MBINIT_REPAIRVAL_ModulePartner_end<= 1'b0;
        o_VAL_Result_logged                 <= 1'b0;
        o_enable_cons                       <= 1'b1;

        case (NS)

            INIT_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REPAIRVAL_init_resp;
            end

            RESULT_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REPAIRVAL_result_resp;
                o_VAL_Result_logged <= i_VAL_Result_logged;
            end

            DONE_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REPAIRVAL_done_resp;
            end

            DONE: begin
                o_MBINIT_REPAIRVAL_ModulePartner_end <= 1'b1;
            end

            default: ;
        endcase
    end
end

endmodule
