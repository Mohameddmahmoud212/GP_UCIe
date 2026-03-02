module REPAIRCLK_Module (
    input               CLK,
    input               rst_n,
    input               i_MBINIT_CAL_end,
    input               i_CLK_Track_done,
    input [3:0]         i_Rx_SbMessage,
    input               i_Busy_SideBand,
    input               i_msg_valid,
    input               i_falling_edge_busy,
    input               i_ValidOutDatat_ModulePartner, 
    input [2:0]         i_Clock_track_result_logged,

    output reg          o_train_error_req,
    output reg          o_MBINIT_REPAIRCLK_Pattern_En,
    output reg          o_MBINIT_REPAIRCLK_Module_end,
    output reg [3:0]    o_TX_SbMessage,
    output reg          o_ValidOutDatat_Module
);

localparam MBINI_REPAIRCLK_init_req     = 4'b0001;
localparam MBINIT_REPAIRCLK_init_resp   = 4'b0010;
localparam MBINIT_REPAIRCLK_result_req  = 4'b0011;
localparam MBINIT_REPAIRCLK_result_resp = 4'b0100;
localparam MBINIT_REPAIRCLK_done_req    = 4'b0101;
localparam MBINIT_REPAIRCLK_done_resp   = 4'b0110;

// FSM states
typedef enum logic [3:0] {
    IDLE,
    REPAIRCLK_INIT_REQ,
    CLKPATTERN,
    REPAIRCLK_RESULT_REQ,
    REPAIRCLK_CHECK_RESULT,
    REPAIRCLK_DONE_REQ,
    REPAIRCLK_DONE,
    REPAIRCLK_HANDLE_VALID,
    REPAIRCLK_CHECK_BUSY_RESULT,
    REPAIRCLK_CHECK_BUSY_DONE
} state_t;

state_t CS, NS;

always @(posedge CLK or negedge rst_n) begin
    if(!rst_n) CS <= IDLE;
    else CS <= NS;
end

always @(*) begin
    NS = CS;
    case(CS)
        IDLE: if(i_MBINIT_CAL_end && ~i_Busy_SideBand) NS = REPAIRCLK_INIT_REQ;
        REPAIRCLK_INIT_REQ: if(i_falling_edge_busy) NS = REPAIRCLK_HANDLE_VALID;
        REPAIRCLK_HANDLE_VALID: begin
            if(i_Rx_SbMessage == MBINIT_REPAIRCLK_init_resp && i_msg_valid) NS = CLKPATTERN;
            else if(i_Rx_SbMessage == MBINIT_REPAIRCLK_result_resp && i_msg_valid) NS = REPAIRCLK_CHECK_RESULT;
            else if(i_Rx_SbMessage == MBINIT_REPAIRCLK_done_resp && i_msg_valid) NS = REPAIRCLK_DONE;
        end
        CLKPATTERN: if(i_CLK_Track_done) NS = REPAIRCLK_CHECK_BUSY_RESULT;
        REPAIRCLK_CHECK_BUSY_RESULT: if(~i_Busy_SideBand && ~i_ValidOutDatat_ModulePartner) NS = REPAIRCLK_RESULT_REQ;
        REPAIRCLK_RESULT_REQ: if(i_falling_edge_busy && ~i_ValidOutDatat_ModulePartner) NS = REPAIRCLK_HANDLE_VALID;
        REPAIRCLK_CHECK_RESULT: if(i_Clock_track_result_logged == 3'b111) NS = REPAIRCLK_CHECK_BUSY_DONE; else NS = IDLE;
        REPAIRCLK_CHECK_BUSY_DONE: if(~i_Busy_SideBand && ~i_ValidOutDatat_ModulePartner) NS = REPAIRCLK_DONE_REQ;
        REPAIRCLK_DONE_REQ: if(i_falling_edge_busy && ~i_ValidOutDatat_ModulePartner) NS = REPAIRCLK_HANDLE_VALID;
        REPAIRCLK_DONE: if(~i_MBINIT_CAL_end) NS = IDLE;
        default: NS = IDLE;
    endcase
end

always @(posedge CLK or negedge rst_n) begin
    if(!rst_n) begin
        o_train_error_req <= 0;
        o_MBINIT_REPAIRCLK_Pattern_En <= 0;
        o_MBINIT_REPAIRCLK_Module_end <= 0;
        o_TX_SbMessage <= 4'b0000;
        o_ValidOutDatat_Module <= 0;
    end else begin
        o_train_error_req <= 0;
        o_MBINIT_REPAIRCLK_Pattern_En <= 0;
        o_MBINIT_REPAIRCLK_Module_end <= 0;
        o_TX_SbMessage <= 4'b0000;
        o_ValidOutDatat_Module <= 0;
        case(NS)
            REPAIRCLK_INIT_REQ: begin o_ValidOutDatat_Module <= 1; o_TX_SbMessage <= MBINI_REPAIRCLK_init_req; end
            CLKPATTERN: o_MBINIT_REPAIRCLK_Pattern_En <= 1;
            REPAIRCLK_RESULT_REQ: begin o_ValidOutDatat_Module <= 1; o_TX_SbMessage <= MBINIT_REPAIRCLK_result_req; end
            REPAIRCLK_CHECK_RESULT: if(i_Clock_track_result_logged != 3'b111) o_train_error_req <= 1;
            REPAIRCLK_DONE_REQ: begin o_ValidOutDatat_Module <= 1; o_TX_SbMessage <= MBINIT_REPAIRCLK_done_req; end
            REPAIRCLK_DONE: o_MBINIT_REPAIRCLK_Module_end <= 1;
        endcase
    end
end

endmodule
