module REVERSALMB_Module (   
    input               CLK,
    input               rst_n,
    input               i_REPAIRVAL_end,
    input               i_REVERSAL_done,
    input [3:0]         i_Rx_SbMessage,
    input               i_Busy_SideBand,
    input               i_msg_valid,
    input               i_LaneID_Pattern_done,
    input               i_falling_edge_busy, 
    input [15:0]        i_REVERSAL_Result_logged, //from rx_sb when it responed with resp on result on i_Rx_SbMessage

    output reg [1:0]    o_MBINIT_REVERSALMB_LaneID_Pattern_En,
    output reg          o_MBINIT_REVERSALMB_ApplyReversal_En,       
    output reg          o_MBINIT_REVERSALMB_Module_end,
    output reg [3:0]    o_TX_SbMessage,
    output reg          o_ValidOutDatat_Module,
    output              o_train_error_req_reversalmb
);

integer  i;
reg [3:0] CS, NS;   // CS current state, NS next state
reg [3:0] one_count;
reg DONE_CHECK;
reg handle_error_req;

////////////////////////////////////////////////////////////////////////////////
// Sideband messages
////////////////////////////////////////////////////////////////////////////////
localparam MBINI_REVERSALMB_init_req            = 4'b0001;
localparam MBINIT_REVERSALMB_init_resp          = 4'b0010;
localparam MBINIT_REVERSALMB_clear_error_req    = 4'b0011;
localparam MBINIT_REVERSALMB_clear_error_resp   = 4'b0100;
localparam MBINIT_REVERSALMB_result_req         = 4'b0101;
localparam MBINIT_REVERSALMB_result_resp        = 4'b0110;
localparam MBINIT_REVERSALMB_done_req           = 4'b0111;
localparam MBINIT_REVERSALMB_done_resp          = 4'b1000;

////////////////////////////////////////////////////////////////////////////////
// State machine states
////////////////////////////////////////////////////////////////////////////////
localparam IDLE                         = 0;
localparam REVERSALMB_INIT_REQ          = 1;
localparam REVERSALMB_CLEAR_ERROR_REQ   = 2;
localparam REVERSALMB_LANEID_PATTER     = 3;
localparam REVERSALMB_RESULT_REQ        = 4;
localparam REVERSALMB_CHECK_RESULT      = 5;
localparam REVERSALMB_APPLY_REVERSAL    = 6;
localparam REVERSALMB_DONE_REQ          = 7;
localparam REVERSALMB_DONE              = 8;
localparam REVERSALMB_HANDLE_VALID      = 9;
localparam REVERSALMB_CHECK_BUSY_CLEAR  = 10;
localparam REVERSALMB_CHECK_BUSY_RESULT = 11;
localparam REVERSALMB_CHECK_BUSY_DONE   = 12;

assign o_train_error_req_reversalmb = (CS == REVERSALMB_CHECK_RESULT && one_count < 8 && DONE_CHECK && handle_error_req);

////////////////////////////////////////////////////////////////////////////////
// State register
////////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) CS <= IDLE;
    else CS <= NS;
end

////////////////////////////////////////////////////////////////////////////////
// Next-state logic
////////////////////////////////////////////////////////////////////////////////
always @(*) begin
    NS = CS; // default
    case (CS)
        IDLE: if (i_REPAIRVAL_end && ~i_Busy_SideBand) NS = REVERSALMB_INIT_REQ;

        REVERSALMB_INIT_REQ: if (~i_REPAIRVAL_end) NS = IDLE;
                             else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_HANDLE_VALID: if (~i_REPAIRVAL_end) NS = IDLE;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_init_resp) NS = REVERSALMB_CHECK_BUSY_CLEAR;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_clear_error_resp) NS = REVERSALMB_LANEID_PATTER;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_result_resp) NS = REVERSALMB_CHECK_RESULT;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_done_resp) NS = REVERSALMB_DONE;

        REVERSALMB_CHECK_BUSY_CLEAR: if (~i_REPAIRVAL_end) NS = IDLE;
                                     else if (~i_Busy_SideBand) NS = REVERSALMB_CLEAR_ERROR_REQ;

        REVERSALMB_CLEAR_ERROR_REQ: if (~i_REPAIRVAL_end) NS = IDLE;
                                     else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_LANEID_PATTER: if (~i_REPAIRVAL_end) NS = IDLE;
                                   else if (i_LaneID_Pattern_done) NS = REVERSALMB_CHECK_BUSY_RESULT;

        REVERSALMB_CHECK_BUSY_RESULT: if (~i_REPAIRVAL_end) NS = IDLE;
                                      else if (~i_Busy_SideBand) NS = REVERSALMB_RESULT_REQ;

        REVERSALMB_RESULT_REQ: if (~i_REPAIRVAL_end) NS = IDLE;
                               else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_CHECK_RESULT: if (~i_REPAIRVAL_end) NS = IDLE;
                                 else if (one_count >= 8 && DONE_CHECK) NS = REVERSALMB_CHECK_BUSY_DONE;
                                 else if (one_count < 8 && DONE_CHECK) NS = REVERSALMB_APPLY_REVERSAL;

        REVERSALMB_CHECK_BUSY_DONE: if (~i_REPAIRVAL_end) NS = IDLE;
                                    else if (~i_Busy_SideBand) NS = REVERSALMB_DONE_REQ;

        REVERSALMB_APPLY_REVERSAL: if (~i_REPAIRVAL_end) NS = IDLE;
                                   else if (i_REVERSAL_done) NS = REVERSALMB_CHECK_BUSY_CLEAR;

        REVERSALMB_DONE_REQ: if (~i_REPAIRVAL_end) NS = IDLE;
                              else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_DONE: if (~i_REPAIRVAL_end) NS = IDLE;

        default: NS = IDLE;
    endcase
end

////////////////////////////////////////////////////////////////////////////////
// Combinational result counting
////////////////////////////////////////////////////////////////////////////////
always @(*) begin
    one_count = 0;
    for (i = 0; i < 16; i = i + 1) one_count = one_count + i_REVERSAL_Result_logged[i];
    DONE_CHECK = 1'b1;
end

////////////////////////////////////////////////////////////////////////////////
// Registered outputs
////////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) begin
        o_MBINIT_REVERSALMB_LaneID_Pattern_En <= 0;
        o_MBINIT_REVERSALMB_ApplyReversal_En  <= 0;
        o_MBINIT_REVERSALMB_Module_end        <= 0;
        o_TX_SbMessage                        <= 4'b0000;
        o_ValidOutDatat_Module                <= 0;
        handle_error_req                      <= 0;
    end else begin
        // defaults
        o_MBINIT_REVERSALMB_LaneID_Pattern_En <= 0;
        o_MBINIT_REVERSALMB_ApplyReversal_En  <= 0;
        o_MBINIT_REVERSALMB_Module_end        <= 0;
        o_TX_SbMessage                        <= 4'b0000;
        o_ValidOutDatat_Module                <= 0;

        // handle_error_req synchronous update
        if (NS == REVERSALMB_APPLY_REVERSAL) handle_error_req <= 1'b1;
        else if (NS == REVERSALMB_DONE) handle_error_req <= 1'b0;

        case (NS)
            REVERSALMB_INIT_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage <= MBINI_REVERSALMB_init_req;
            end
            REVERSALMB_CLEAR_ERROR_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_clear_error_req;
            end
            REVERSALMB_LANEID_PATTER: begin
                o_MBINIT_REVERSALMB_LaneID_Pattern_En <= 2'b11; // PER-LANE enable
            end
            REVERSALMB_RESULT_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_result_req;
            end
            REVERSALMB_APPLY_REVERSAL: begin
                o_MBINIT_REVERSALMB_ApplyReversal_En <= 1'b1;
            end
            REVERSALMB_DONE_REQ: begin
                o_ValidOutDatat_Module <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_done_req;
            end
            REVERSALMB_DONE: begin
                o_MBINIT_REVERSALMB_Module_end <= 1'b1;
            end
        endcase
    end
end

endmodule
