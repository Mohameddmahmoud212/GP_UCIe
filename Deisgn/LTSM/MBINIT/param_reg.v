module PARAM_REG (
    input               CLK,
    input               rst_n,
    input               i_Enable_Checker,
    input      [2:0]    i_Final_MaxDataRate,
    output reg [4:0]    o_TX_VoltageSwing,
    output reg [2:0]    o_MaxDataRate,
    output reg          o_TX_ClockMode,
    output reg          o_TX_PhaseClock,
    output reg [2:0]    o_Final_MaxDataRate
);
    
    always @(posedge CLK or negedge rst_n) begin
        if (~rst_n) begin
            o_TX_VoltageSwing <= 5'b00000;
            o_MaxDataRate      <= 3'b000;
            o_TX_ClockMode     <= 1'b0;
            o_TX_PhaseClock    <= 1'b0;
            o_Final_MaxDataRate<= 3'b000;
        end else begin
            o_TX_VoltageSwing <= 5'b10101; // 21 decimal
            o_MaxDataRate      <= 3'b011;   // 3 decimal
            o_TX_ClockMode     <= 1'b1;     // 1
            o_TX_PhaseClock    <= 1'b0;     // 0
            if (i_Enable_Checker) 
                o_Final_MaxDataRate <= i_Final_MaxDataRate;
        end
    end

endmodule
