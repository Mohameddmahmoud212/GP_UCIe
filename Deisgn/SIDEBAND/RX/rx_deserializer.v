module SB_RX_DESER (
    input    i_clk,
    input    i_clk_pll,
    input    i_rst_n,
    input    ser_data_in,
    output reg [63:0] par_data_out,
    output reg de_ser_done
);

    reg [6:0]  bit_count;
    reg [63:0] shift_reg;
    reg [63:0] capture_reg;  // ← saved by i_clk before reset
    reg        capture_valid;

    // i_clk domain — shift and capture
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            bit_count     <= 0;
            shift_reg     <= 0;
            capture_reg   <= 0;
            capture_valid <= 0;
        end else begin
            if (bit_count < 7'd63) begin
                shift_reg <= {shift_reg[62:0], ser_data_in}; 
                bit_count <= bit_count + 1;
                
            end else if (bit_count == 7'd63) begin
                capture_reg   <= {shift_reg[62:0], ser_data_in}; //capture last bit here
                capture_valid <= 1;
                bit_count     <= 0;
                shift_reg     <= 0;
            end
        end
end

    // i_clk_pll domain — just reads stable capture_reg
    always @(posedge i_clk_pll or negedge i_rst_n) begin 
        if (~i_rst_n) begin
            de_ser_done  <= 0;
            par_data_out <= 0;
        end else begin
            de_ser_done  <= 0;  //to be pulse
            if (capture_valid && !de_ser_done) begin
                par_data_out <= capture_reg;  //always stable
                de_ser_done  <= 1;
                capture_valid <= 0;  // default
            end else if (!capture_valid) begin
                de_ser_done  <= 0;
            end
        end
    end

endmodule