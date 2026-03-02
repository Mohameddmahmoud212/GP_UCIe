module repair_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,

    // sideband decoded RX
    input  wire [3:0] i_sideband_message,
    input  wire       i_sideband_valid,

    // arbitration / valid
    input  wire       i_busy_negedge_detected,
    input  wire       i_valid_rx,

    // local lanes status (from linkspeed)
    input  wire       i_first_8_lanes_are_functional,
    input  wire       i_second_8_lanes_are_functional,

    // outputs to sideband
    output reg  [3:0] o_sideband_message,
    output reg        o_valid_tx,

    // decision to send on sideband (repair encoding)
    output reg  [2:0] o_sideband_data_lanes_encoding,

    // finishing ack
    output reg        o_test_ack
);

    localparam [3:0] START_REQ = 4'b0001;
    localparam [3:0] START_RSP = 4'b0010;
    localparam [3:0] END_REQ   = 4'b0011;
    localparam [3:0] END_RSP   = 4'b0100;

    localparam IDLE         = 3'd0;
    localparam START_REQ_ST = 3'd1;
    localparam RUN_ST       = 3'd2;
    localparam END_REQ_ST   = 3'd3;
    localparam DONE_ST      = 3'd4;

    reg [2:0] cs, ns;

    // state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= IDLE;
        else        cs <= ns;
    end

    // next state
    always @(*) begin
        ns = cs;
        case (cs)
            IDLE: begin
                if (i_en) ns = START_REQ_ST;
            end

            START_REQ_ST: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_sideband_message == START_RSP))
                    ns = RUN_ST;
            end

            RUN_ST: begin
                if (!i_en) ns = IDLE;
                else       ns = END_REQ_ST; 
            end

            END_REQ_ST: begin
                if (!i_en) ns = IDLE;
                else if (i_sideband_valid && (i_sideband_message == END_RSP))
                    ns = DONE_ST;
            end

            DONE_ST: begin
                if (!i_en) ns = IDLE;
            end

            default: ns = IDLE;
        endcase
    end

    // output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message            <= 4'b0000;
            o_sideband_data_lanes_encoding<= 3'b000;
            o_test_ack                    <= 1'b0;
        end else begin
            if (!i_en) begin
                o_test_ack <= 1'b0;
            end

            case (cs)
                IDLE: begin
                    o_sideband_message <= 4'b0000;
                    o_test_ack         <= 1'b0;
                    if ( i_first_8_lanes_are_functional && i_second_8_lanes_are_functional )
                        o_sideband_data_lanes_encoding <= 3'b000;
                    else if ( i_first_8_lanes_are_functional && !i_second_8_lanes_are_functional )
                        o_sideband_data_lanes_encoding <= 3'b001;
                    else if ( !i_first_8_lanes_are_functional && i_second_8_lanes_are_functional )
                        o_sideband_data_lanes_encoding <= 3'b010;
                    else
                        o_sideband_data_lanes_encoding <= 3'b011;

                    if (ns == START_REQ_ST) begin
                        o_sideband_message <= START_REQ;
                    end
                end

                RUN_ST: begin
                    if (ns == END_REQ_ST) begin
                        o_sideband_message <= END_REQ;
                    end
                end

                END_REQ_ST: begin
                    if (ns == DONE_ST) begin
                        o_sideband_message <= 4'b0000;
                        o_test_ack         <= 1'b1;
                    end
                end

                DONE_ST: begin
                    o_test_ack <= 1'b1; // held until i_en drops
                end

                default: ;
            endcase
        end
    end

    // valid pulse (same family)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_tx <= 1'b0;
        end else if ((cs == IDLE && ns == START_REQ_ST) || (cs == RUN_ST && ns == END_REQ_ST)) begin
            o_valid_tx <= 1'b1;
        end else if (i_busy_negedge_detected && ~i_valid_rx) begin
            o_valid_tx <= 1'b0;
        end
    end

endmodule
