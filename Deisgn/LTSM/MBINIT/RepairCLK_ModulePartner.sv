module RepairCLK_ModulePartner (
    input wire          CLK,
    input wire          rst_n,
    input wire          i_MBINIT_CAL_end,
    input wire [2:0]    i_Clock_track_result_logged,
    input wire [3:0]    i_RX_SbMessage,
    input wire          i_falling_edge_busy, 
    input wire          i_Busy_SideBand,
    input wire          i_msg_valid,

    output reg [2:0]    o_Clock_track_result_logged,
    output reg [3:0]    o_TX_SbMessage,
    output reg          o_MBINIT_REPAIRCLK_ModulePartner_end,
    output reg          o_clear_clk_detection,
    output reg          o_ValidOutDatat_ModulePartner
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
    REPAIRCLK_CHECK_INIT_REQ,
    REPAIRCLK_INIT_RESP,
    REPAIRCLK_RESULT_RESP,
    REPAIRCLK_DONE_RESP,
    REPAIRCLK_DONE,
    REPAIRCLK_HANDLE_VALID,
    REPAIRCLK_CHECK_BUSY_INIT,
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
        IDLE: if(i_MBINIT_CAL_end) NS = REPAIRCLK_CHECK_INIT_REQ;
        REPAIRCLK_CHECK_INIT_REQ: if(i_RX_SbMessage == MBINI_REPAIRCLK_init_req && i_msg_valid) NS = REPAIRCLK_CHECK_BUSY_INIT;
        REPAIRCLK_CHECK_BUSY_INIT: if(~i_Busy_SideBand) NS = REPAIRCLK_INIT_RESP;
        REPAIRCLK_INIT_RESP: if(i_falling_edge_busy) NS = REPAIRCLK_HANDLE_VALID;
        REPAIRCLK_HANDLE_VALID: begin
            if(i_RX_SbMessage == MBINIT_REPAIRCLK_result_req && i_msg_valid) NS = REPAIRCLK_CHECK_BUSY_RESULT;
            else if(i_RX_SbMessage == MBINIT_REPAIRCLK_done_req && i_msg_valid) NS = REPAIRCLK_CHECK_BUSY_DONE;
        end
        REPAIRCLK_CHECK_BUSY_RESULT: if(~i_Busy_SideBand) NS = REPAIRCLK_RESULT_RESP;
        REPAIRCLK_RESULT_RESP: if(i_falling_edge_busy) NS = REPAIRCLK_HANDLE_VALID;
        REPAIRCLK_CHECK_BUSY_DONE: if(~i_Busy_SideBand) NS = REPAIRCLK_DONE_RESP;
        REPAIRCLK_DONE_RESP: if(i_falling_edge_busy) NS = REPAIRCLK_DONE;
        REPAIRCLK_DONE: if(~i_MBINIT_CAL_end) NS = IDLE;
        default: NS = IDLE;
    endcase
end

always @(posedge CLK or negedge rst_n) begin
    if(!rst_n) begin
        o_ValidOutDatat_ModulePartner <= 0;
        o_Clock_track_result_logged <= 3'b000;
        o_TX_SbMessage <= 4'b0000;
        o_MBINIT_REPAIRCLK_ModulePartner_end <= 0;
        o_clear_clk_detection <=0;
    end else begin
        o_ValidOutDatat_ModulePartner <= 0;
        o_Clock_track_result_logged <= 3'b000;
        o_TX_SbMessage <= 4'b0000;
        o_MBINIT_REPAIRCLK_ModulePartner_end <= 0;
        o_clear_clk_detection<=0;
        case(NS)
            REPAIRCLK_INIT_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1;
                o_TX_SbMessage <= MBINIT_REPAIRCLK_init_resp;
                o_clear_clk_detection <= 1;
            end
            REPAIRCLK_RESULT_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1;
                o_TX_SbMessage <= MBINIT_REPAIRCLK_result_resp;
                o_Clock_track_result_logged <= i_Clock_track_result_logged;
            end
            REPAIRCLK_DONE_RESP: begin
                o_ValidOutDatat_ModulePartner <= 1;
                o_TX_SbMessage <= MBINIT_REPAIRCLK_done_resp;
            end
            REPAIRCLK_DONE: o_MBINIT_REPAIRCLK_ModulePartner_end <= 1;
        endcase
    end
end

endmodule
