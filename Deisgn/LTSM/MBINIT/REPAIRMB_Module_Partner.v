module REPAIRMB_Module_Partner (
    input                 CLK,
    input                 rst_n,
    input                 MBINIT_REVERSALMB_end,
    input                 i_Busy_SideBand,
    input                 i_falling_edge_busy,
    input [3:0]           i_RX_SbMessage,
    input                 i_msg_valid,
    input [1:0]           i_Functional_Lanes, // from RX sideband in msginfo
    input                 i_Done_Repeater,    // from REPAIRMB_Module
    input                 i_Transmitter_initiated_Data_to_CLK_en,

    output reg            o_Start_Repeater,   // to REPAIRMB_Module
    output wire           o_train_error,      // fixed: now wire
    output reg            o_MBINIT_REPAIRMB_Module_Partner_end,
    output reg            o_ValidOutDatat_REPAIRMB_Module_Partner,
    output reg [3:0]      o_TX_SbMessage,
    output reg            apply_repeater,     // tell REPAIRMB_Module to apply repeater
    output reg [1:0]      o_Functional_Lanes  // to width degrade module
);

    reg [3:0] CS, NS;   // Current state, next state
    reg i_start_check;
    reg i_second_check;
    reg continue_r; // to REPAIRMB_Module(tx) to apply repeater
    wire o_done_check;
    wire o_go_to_repeat;
    wire o_go_to_train_error;
    wire o_continue_check;

    // Checker instance
    CHECKER_REPAIRMB_Module_Partner CHECKER_INST (
        .CLK(CLK),
        .rst_n(rst_n),
        .i_start_check(i_start_check),
        .i_second_check(i_second_check),
        .i_Functional_Lanes(i_Functional_Lanes),
        .i_Transmitter_initiated_Data_to_CLK_en(i_Transmitter_initiated_Data_to_CLK_en),
        .o_done_check(o_done_check),
        .o_go_to_repeat(o_go_to_repeat),
        .o_go_to_train_error(o_go_to_train_error),
        .o_continue(o_continue_check)
    );

    assign o_train_error = o_go_to_train_error;  // now valid since o_train_error is wire

    // State machine states
    localparam  IDLE                                = 0,
                REPAIRMB_CHECK_REQ                  = 1,
                REPAIRMB_CHECK_BUSY_START           = 2,
                REPAIRMB_START_RESP                 = 3,
                REPAIRMB_HANDLE_VALID               = 4,
                REPAIRMB_CHECK_WIDTH_DEGRADE        = 5,
                REPAIRMB_APPLY_REPEAT               = 6,
                REPAIRMB_CHECK_BUSY_DEGRADE_RESP    = 7,
                REPAIRMB_DEGRADE_RESP               = 8,
                REPAIRMB_CHECK_BUSY_END_RESP        = 9,
                REPAIRMB_END_RESP                   = 10,
                REPAIRMB_DONE                       = 11;

    // State memory
    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n)
            CS <= IDLE;
        else
            CS <= NS;
    end

    // Next state logic
    always @(*) begin
        NS = CS;
        case (CS)
            IDLE: begin
                if (MBINIT_REVERSALMB_end) NS = REPAIRMB_CHECK_REQ;
            end
            REPAIRMB_CHECK_REQ: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (i_RX_SbMessage == 4'b0001 && i_msg_valid) NS = REPAIRMB_CHECK_BUSY_START; // start_req
            end
            REPAIRMB_CHECK_BUSY_START: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (~i_Busy_SideBand) NS = REPAIRMB_START_RESP;
            end
            REPAIRMB_START_RESP: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (i_falling_edge_busy) NS = REPAIRMB_HANDLE_VALID;
            end
            REPAIRMB_HANDLE_VALID: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (i_RX_SbMessage == 4'b0101 && i_msg_valid && ~i_Transmitter_initiated_Data_to_CLK_en)
                    NS = REPAIRMB_CHECK_WIDTH_DEGRADE;
                else if (i_RX_SbMessage == 4'b0011 && continue_r && i_msg_valid)
                    NS = REPAIRMB_CHECK_BUSY_END_RESP;
                else if (apply_repeater)
                    NS = REPAIRMB_APPLY_REPEAT;
            end
            REPAIRMB_CHECK_WIDTH_DEGRADE: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (o_done_check) NS = REPAIRMB_CHECK_BUSY_DEGRADE_RESP;
            end
            REPAIRMB_APPLY_REPEAT: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (i_Done_Repeater) NS = REPAIRMB_HANDLE_VALID;
            end
            REPAIRMB_CHECK_BUSY_DEGRADE_RESP: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (~i_Busy_SideBand) NS = REPAIRMB_DEGRADE_RESP;
            end
            REPAIRMB_DEGRADE_RESP: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (i_falling_edge_busy) NS = REPAIRMB_HANDLE_VALID;
            end
            REPAIRMB_CHECK_BUSY_END_RESP: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (~i_Busy_SideBand) NS = REPAIRMB_END_RESP;
            end
            REPAIRMB_END_RESP: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
                else if (i_falling_edge_busy) NS = REPAIRMB_DONE;
            end
            REPAIRMB_DONE: begin
                if (~MBINIT_REVERSALMB_end) NS = IDLE;
            end
            default: NS = IDLE;
        endcase
    end

    // Output logic
    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n) begin
            o_TX_SbMessage <= 4'b0000;
            o_MBINIT_REPAIRMB_Module_Partner_end <= 0;
            o_ValidOutDatat_REPAIRMB_Module_Partner <= 0;
            o_Functional_Lanes <= 2'b11;
            o_Start_Repeater <= 0;
            i_start_check <= 0;
            continue_r <= 0;
            apply_repeater <= 0;
            i_second_check <= 0;
        end else begin
            // Default values
            o_TX_SbMessage <= 4'b0000;
            o_MBINIT_REPAIRMB_Module_Partner_end <= 0;
            o_ValidOutDatat_REPAIRMB_Module_Partner <= 0;
            o_Start_Repeater <= 0;
            i_start_check <= 0;

            // Checker logic
            if (CS == REPAIRMB_CHECK_WIDTH_DEGRADE && o_done_check) begin
                if (o_go_to_repeat) begin
                    o_Functional_Lanes <= i_Functional_Lanes;
                    apply_repeater <= 1'b1;
                    continue_r <= 0;
                end else if (o_continue_check) begin
                    continue_r <= 1'b1;
                    apply_repeater <= 0;
                end
            end

            case (NS)
                REPAIRMB_START_RESP: begin
                    o_ValidOutDatat_REPAIRMB_Module_Partner <= 1'b1;
                    o_TX_SbMessage <= 4'b0010; // start_resp
                end
                REPAIRMB_CHECK_WIDTH_DEGRADE: begin
                    i_start_check <= 1'b1;
                end
                REPAIRMB_APPLY_REPEAT: begin
                    o_Start_Repeater <= 1'b1;
                    apply_repeater <= 0;
                end
                REPAIRMB_DEGRADE_RESP: begin
                    o_ValidOutDatat_REPAIRMB_Module_Partner <= 1'b1;
                    o_TX_SbMessage <= 4'b0110; // apply_degrade_resp
                end
                REPAIRMB_END_RESP: begin
                    o_ValidOutDatat_REPAIRMB_Module_Partner <= 1'b1;
                    o_TX_SbMessage <= 4'b0100; // end_resp
                    continue_r <= 0;
                    i_second_check <= 0;
                end
                REPAIRMB_DONE: begin
                    o_MBINIT_REPAIRMB_Module_Partner_end <= 1;
                end
            endcase
        end
    end

    // Second check logic
    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n)
            i_second_check <= 0;
        else if (i_Done_Repeater)
            i_second_check <= 1;
    end

endmodule
