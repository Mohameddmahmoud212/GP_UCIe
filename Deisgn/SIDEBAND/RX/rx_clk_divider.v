module clk_div8 (
    input  wire i_clk,     // input clock
    input  wire i_rst_n,   // active-low reset
    output reg  o_clk_div8 // divided clock (clk/8)
);

    reg counter;  // 2i2fish de ##// 3-bit counter (0 to 7)

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter     <= 1'd0;
            o_clk_div8  <= 1'b0;
        end else begin
            counter <= counter + 3'd1;

            // Toggle output every 4 cycles (gives divide-by-8 total)
            if (counter == 3'd1)
                o_clk_div8 <= ~o_clk_div8;
        end
    end

endmodule