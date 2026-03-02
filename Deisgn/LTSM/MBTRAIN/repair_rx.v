module repair_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,

    input  wire [3:0] i_sideband_message,
    input  wire       i_sideband_valid,

    input  wire       i_busy_negedge_detected,
    input  wire       i_valid_tx,

    // received encoding from partner (already decoded by sideband block)
    input  wire [2:0] i_sideband_data_lanes_encoding,

    output reg  [3:0] o_sideband_message,
    output reg        o_valid_rx,

    // expose partner results in simple form
    output reg        o_remote_partner_first_8_lanes_result,
    output reg        o_remote_partner_second_8_lanes_result,

    output reg        o_test_ack
);

    localparam [3:0] START_REQ = 4'b0001;
    localparam [3:0] START_RSP = 4'b0010;
    localparam [3:0] END_REQ   = 4'b0011;
    localparam [3:0] END_RSP   = 4'b0100;
   
    localparam ST_IDLE       = 3'd0;
    localparam ST_WAIT_START = 3'd1;
    localparam ST_GOT_START  = 3'd2;
    localparam ST_WAIT_END   = 3'd3;
    localparam ST_REPLY_END  = 3'd4;
    localparam ST_DONE       = 3'd5;

    reg [2:0] cs, ns;

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs <= ST_IDLE;
        else        cs <= ns;
    end

    always @(*) begin
        ns = cs;
        case (cs)
            ST_IDLE: begin
                if (i_en) ns = ST_WAIT_START;
            end

            ST_WAIT_START: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_sideband_message == START_REQ))
                    ns = ST_GOT_START;
            end

            ST_GOT_START: begin
                if (!i_en) ns = ST_IDLE;
                else       ns = ST_WAIT_END;
            end

            ST_WAIT_END: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_sideband_valid && (i_sideband_message == END_REQ))
                    ns = ST_REPLY_END;
            end

            ST_REPLY_END: begin
                if (!i_en) ns = ST_IDLE;
                else if (i_busy_negedge_detected && ~i_valid_tx)
                    ns = ST_DONE;
            end

            ST_DONE: begin
                if (!i_en) ns = ST_IDLE;
            end

            default: ns = ST_IDLE;
        endcase
    end
    always @(*) begin
        // defaults
        o_remote_partner_first_8_lanes_result  = 1'b0;
        o_remote_partner_second_8_lanes_result = 1'b0;

        case (i_sideband_data_lanes_encoding)
            3'b000 : begin o_remote_partner_first_8_lanes_result=1'b1; o_remote_partner_second_8_lanes_result=1'b1; end
            3'b001 : begin o_remote_partner_first_8_lanes_result=1'b1; o_remote_partner_second_8_lanes_result=1'b0; end
            3'b010 : begin o_remote_partner_first_8_lanes_result=1'b0; o_remote_partner_second_8_lanes_result=1'b1; end
            default: begin o_remote_partner_first_8_lanes_result=1'b0; o_remote_partner_second_8_lanes_result=1'b0; end
        endcase
    end

    // output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_sideband_message <= 4'b0000;
            o_test_ack         <= 1'b0;
        end else begin
            if (!i_en) o_test_ack <= 1'b0;

            case (cs)
                ST_IDLE: begin
                end

                ST_WAIT_START: begin
                    if (ns == ST_GOT_START) begin
                        o_sideband_message <= START_RSP;
                    end
                end

                ST_GOT_START: begin
                end

                ST_WAIT_END: begin
                    // wait for END_REQ
                    if (cs == ST_WAIT_END && ns == ST_REPLY_END) begin
                        o_sideband_message <= END_RSP;
                    end
                end

                ST_REPLY_END: begin
                    
                    if (ns == ST_DONE) begin
                        o_test_ack         <= 1'b1;
                    end
                end

                ST_DONE: begin
                    o_test_ack <= 1'b1;
                end

                default: ;
            endcase
        end
    end

    // VALID RX generation (same family)
   always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid_rx <= 1'b0;
        end else if ((cs == ST_WAIT_START && ns == ST_GOT_START) || (cs == ST_WAIT_END && ns == ST_REPLY_END)) begin
            o_valid_rx <= 1'b1;
        end else if (i_busy_negedge_detected && ~i_valid_tx) begin
            o_valid_rx <= 1'b0;
        end
    end

endmodule