module REPAIRVAL_Module (
    input               CLK,
    input               rst_n,

    // Control / phase inputs
    input               i_REPAIRCLK_end,              // previous phase done
    input               i_VAL_Pattern_done,            // abstracted pattern completion
    input               i_VAL_Result_logged,           // 1 = pass, 0 = fail

    // Sideband interface
    input  [3:0]        i_Rx_SbMessage,
    input               i_Busy_SideBand,
    input               i_falling_edge_busy,
    input               i_msg_valid,

    // Outputs
    output reg          o_train_error_req,
    output reg          o_MBINIT_REPAIRVAL_Pattern_En,
    output reg          o_MBINIT_REPAIRVAL_Module_end,
    output reg [3:0]    o_TX_SbMessage,
    output reg          o_ValidOutDatat_Module
);

///////////////////////////////////////////////////////////////////////////////
// Sideband messages
///////////////////////////////////////////////////////////////////////////////
localparam MBINI_REPAIRVAL_init_req     = 4'b0001;
localparam MBINIT_REPAIRVAL_init_resp   = 4'b0010;
localparam MBINIT_REPAIRVAL_result_req  = 4'b0011;
localparam MBINIT_REPAIRVAL_result_resp = 4'b0100;
localparam MBINIT_REPAIRVAL_done_req    = 4'b0101;
localparam MBINIT_REPAIRVAL_done_resp   = 4'b0110;

///////////////////////////////////////////////////////////////////////////////
// FSM states
///////////////////////////////////////////////////////////////////////////////
localparam IDLE                         = 4'd0;
localparam REPAIRVAL_INIT_REQ           = 4'd1;
localparam REPAIRVAL_HANDLE_VALID       = 4'd2;
localparam VALPATTERN                   = 4'd3;
localparam REPAIRVAL_CHECK_BUSY_RESULT  = 4'd4;
localparam REPAIRVAL_RESULT_REQ         = 4'd5;
localparam REPAIRVAL_CHECK_RESULT       = 4'd6;
localparam REPAIRVAL_CHECK_BUSY_DONE    = 4'd7;
localparam REPAIRVAL_DONE_REQ           = 4'd8;
localparam REPAIRVAL_DONE               = 4'd9;

reg [3:0] CS, NS;

///////////////////////////////////////////////////////////////////////////////
// State register
///////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end

///////////////////////////////////////////////////////////////////////////////
// Next-state logic
///////////////////////////////////////////////////////////////////////////////
always @(*) begin
    NS = CS;
    case (CS)

        IDLE: begin
            if (i_REPAIRCLK_end && ~i_Busy_SideBand)
                NS = REPAIRVAL_INIT_REQ;
        end

        REPAIRVAL_INIT_REQ: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_falling_edge_busy)
                NS = REPAIRVAL_HANDLE_VALID;
        end

        REPAIRVAL_HANDLE_VALID: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REPAIRVAL_init_resp)
                NS = VALPATTERN;
            else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REPAIRVAL_result_resp)
                NS = REPAIRVAL_CHECK_RESULT;
            else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REPAIRVAL_done_resp)
                NS = REPAIRVAL_DONE;
        end

        VALPATTERN: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_VAL_Pattern_done)
                NS = REPAIRVAL_CHECK_BUSY_RESULT;
        end

        REPAIRVAL_CHECK_BUSY_RESULT: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (!i_Busy_SideBand)
                NS = REPAIRVAL_RESULT_REQ;
        end

        REPAIRVAL_RESULT_REQ: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_falling_edge_busy)
                NS = REPAIRVAL_HANDLE_VALID;
        end

        REPAIRVAL_CHECK_RESULT: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (!i_VAL_Result_logged)
                NS = IDLE;              // TRAINERROR handled outside
            else
                NS = REPAIRVAL_CHECK_BUSY_DONE;
        end

        REPAIRVAL_CHECK_BUSY_DONE: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (!i_Busy_SideBand)
                NS = REPAIRVAL_DONE_REQ;
        end

        REPAIRVAL_DONE_REQ: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
            else if (i_falling_edge_busy)
                NS = REPAIRVAL_HANDLE_VALID;
        end

        REPAIRVAL_DONE: begin
            if (!i_REPAIRCLK_end)
                NS = IDLE;
        end

        default: NS = IDLE;
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// Output logic
///////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) begin
        o_train_error_req             <= 1'b0;
        o_MBINIT_REPAIRVAL_Pattern_En <= 1'b0;
        o_MBINIT_REPAIRVAL_Module_end <= 1'b0;
        o_TX_SbMessage                <= 4'b0000;
        o_ValidOutDatat_Module        <= 1'b0;
    end else begin
        // defaults
        o_train_error_req             <= 1'b0;
        o_MBINIT_REPAIRVAL_Pattern_En <= 1'b0;
        o_MBINIT_REPAIRVAL_Module_end <= 1'b0;
        o_TX_SbMessage                <= 4'b0000;
        o_ValidOutDatat_Module        <= 1'b0;

        case (NS)

            REPAIRVAL_INIT_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage         <= MBINI_REPAIRVAL_init_req;
            end

            VALPATTERN: begin
                o_MBINIT_REPAIRVAL_Pattern_En <= 1'b1;
            end

            REPAIRVAL_RESULT_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage         <= MBINIT_REPAIRVAL_result_req;
            end

            REPAIRVAL_CHECK_RESULT: begin
                if (!i_VAL_Result_logged)
                    o_train_error_req <= 1'b1;
            end

            REPAIRVAL_DONE_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage         <= MBINIT_REPAIRVAL_done_req;
            end

            REPAIRVAL_DONE: begin
                o_MBINIT_REPAIRVAL_Module_end <= 1'b1;
            end

        endcase
    end
end

endmodule
