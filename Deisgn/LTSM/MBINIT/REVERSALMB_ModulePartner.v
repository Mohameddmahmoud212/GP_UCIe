module REVERSALMB_ModulePartner (
    input wire              CLK,
    input wire              rst_n,
    input wire              i_REPAIRVAL_end,
    input wire [15:0]       i_REVERSAL_Pattern_Result_logged,
    input wire [3:0]        i_Rx_SbMessage,
    input wire              i_falling_edge_busy,
    input wire              i_Busy_SideBand,
    input                   i_msg_valid,

    output reg [15:0]       o_REVERSAL_Pattern_Result_logged,
    output reg [3:0]        o_TX_SbMessage,
    output reg [1:0]        o_Clear_Pattern_Comparator,
    output reg              o_MBINIT_REVERSALMB_ModulePartner_end,
    output reg              o_ValidOutDatat_ModulePartner,
    output reg              o_ValidDataFieldParameters_modulePartner
);

reg [3:0] CS, NS;

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
// FSM states
////////////////////////////////////////////////////////////////////////////////
localparam IDLE                             = 0;
localparam REVERSALMB_CHECK_INIT_REQ        = 1;
localparam REVERSALMB_CHECK_BUSY_INIT_RESP  = 2;
localparam REVERSALMB_INIT_RESP             = 3;
localparam REVERSALMB_HANDLE_VALID          = 4;
localparam REVERSALMB_CHECK_BUSY_CLEAR      = 5;
localparam REVERSALMB_CLEAR_ERROR_RESP      = 6;
localparam REVERSALMB_CHECK_BUSY_RESULT     = 7;
localparam REVERSALMB_RESULT_RESP           = 8;
localparam REVERSALMB_CHECK_BUSY_DONE       = 9;
localparam REVERSALMB_DONE_RESP             = 10;
localparam REVERSALMB_DONE                  = 11;

////////////////////////////////////////////////////////////////////////////////
// FSM state register
////////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) CS <= IDLE;
    else CS <= NS;
end

////////////////////////////////////////////////////////////////////////////////
// Next-state logic
////////////////////////////////////////////////////////////////////////////////
always @(*) begin
    NS = CS;
    case (CS)
        IDLE: if (i_REPAIRVAL_end) NS = REVERSALMB_CHECK_INIT_REQ;

        REVERSALMB_CHECK_INIT_REQ: if (~i_REPAIRVAL_end) NS = IDLE;
                                    else if (i_Rx_SbMessage == MBINI_REVERSALMB_init_req) NS = REVERSALMB_CHECK_BUSY_INIT_RESP;

        REVERSALMB_CHECK_BUSY_INIT_RESP: if (~i_REPAIRVAL_end) NS = IDLE;
                                         else if (~i_Busy_SideBand) NS = REVERSALMB_INIT_RESP;

        REVERSALMB_INIT_RESP: if (~i_REPAIRVAL_end) NS = IDLE;
                              else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_HANDLE_VALID: if (~i_REPAIRVAL_end) NS = IDLE;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_clear_error_req) NS = REVERSALMB_CHECK_BUSY_CLEAR;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_result_req) NS = REVERSALMB_CHECK_BUSY_RESULT;
                                 else if (i_msg_valid && i_Rx_SbMessage == MBINIT_REVERSALMB_done_req) NS = REVERSALMB_CHECK_BUSY_DONE;

        REVERSALMB_CHECK_BUSY_CLEAR: if (~i_REPAIRVAL_end) NS = IDLE;
                                     else if (~i_Busy_SideBand) NS = REVERSALMB_CLEAR_ERROR_RESP;

        REVERSALMB_CLEAR_ERROR_RESP: if (~i_REPAIRVAL_end) NS = IDLE;
                                      else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_CHECK_BUSY_RESULT: if (~i_REPAIRVAL_end) NS = IDLE;
                                       else if (~i_Busy_SideBand) NS = REVERSALMB_RESULT_RESP;

        REVERSALMB_RESULT_RESP: if (~i_REPAIRVAL_end) NS = IDLE;
                                else if (i_falling_edge_busy) NS = REVERSALMB_HANDLE_VALID;

        REVERSALMB_CHECK_BUSY_DONE: if (~i_REPAIRVAL_end) NS = IDLE;
                                    else if (~i_Busy_SideBand) NS = REVERSALMB_DONE_RESP;

        REVERSALMB_DONE_RESP: if (~i_REPAIRVAL_end) NS = IDLE;
                              else if (i_falling_edge_busy) NS = REVERSALMB_DONE;

        REVERSALMB_DONE: if (~i_REPAIRVAL_end) NS = IDLE;

        default: NS = IDLE;
    endcase
end

////////////////////////////////////////////////////////////////////////////////
// Registered output logic
////////////////////////////////////////////////////////////////////////////////
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) begin
        o_REVERSAL_Pattern_Result_logged       <= 16'b0;
        o_TX_SbMessage                         <= 4'b0000;
        o_Clear_Pattern_Comparator             <= 2'b00;
        o_MBINIT_REVERSALMB_ModulePartner_end  <= 0;
        o_ValidOutDatat_ModulePartner          <= 0;
        o_ValidDataFieldParameters_modulePartner<= 0;
    end else begin
        // Default outputs every clock
        o_TX_SbMessage                         <= 4'b0000;
        o_Clear_Pattern_Comparator             <= 2'b00;
        o_ValidOutDatat_ModulePartner          <= 0;
        o_ValidDataFieldParameters_modulePartner<= 0;
        o_MBINIT_REVERSALMB_ModulePartner_end  <= 0;

        case (NS)
            REVERSALMB_INIT_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_init_resp;
            end
            REVERSALMB_CLEAR_ERROR_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_clear_error_resp;
                o_Clear_Pattern_Comparator <= 2'b01;
            end
            REVERSALMB_RESULT_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_result_resp;
                o_ValidDataFieldParameters_modulePartner <= 1'b1;
                o_REVERSAL_Pattern_Result_logged <= i_REVERSAL_Pattern_Result_logged;
            end
            REVERSALMB_DONE_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1'b1;
                o_TX_SbMessage <= MBINIT_REVERSALMB_done_resp;
            end
            REVERSALMB_DONE: begin
                o_MBINIT_REVERSALMB_ModulePartner_end <= 1'b1;
            end
        endcase
    end
end

endmodule
