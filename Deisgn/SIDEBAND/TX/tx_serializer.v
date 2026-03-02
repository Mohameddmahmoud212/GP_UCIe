module sb_tx_serializer(
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire [63:0] i_data,
    input  wire        i_enable,
    input  wire        i_data_valid,
    output wire        TXDATASB,    // ← change to wire
    output reg         o_busy
);

    reg [63:0] shift_reg;
    reg [7:0]  bit_count;

    // Combinational output — no clock delay on first bit
    assign TXDATASB = (i_enable && i_data_valid && !o_busy) ? i_data[63] :
                      o_busy                                ? shift_reg[63] :
                                                              1'b0;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            shift_reg <= 64'd0;
            bit_count <= 8'd0;
            o_busy    <= 1'b0;
        end else begin
            if (i_enable && i_data_valid && !o_busy) begin
                shift_reg <= {i_data[62:0], 1'b0};
                bit_count <= 8'd1;
                o_busy    <= 1'b1;
            end else if (o_busy) begin
                shift_reg <= {shift_reg[62:0], 1'b0};
                if (bit_count == 8'd63) begin
                    o_busy    <= 1'b0;
                    bit_count <= 8'd0;
                end else begin
                    bit_count <= bit_count + 8'd1;
                end
            end
        end
    end

endmodule