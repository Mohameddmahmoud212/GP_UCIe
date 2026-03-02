module Functional_Lane_Setup ( 
    input               CLK,
    input               rst_n,
    input               start_setup,
    input  [15:0]       i_Transmitter_initiated_Data_to_CLK_Result,
    output reg [1:0]    o_Functional_Lanes,
    output reg          done_setup 
);

    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n) begin
            o_Functional_Lanes <= 2'b11; // assume full width functional after reset
            done_setup         <= 1'b0;
        end else if (start_setup) begin
            // Default to no lanes functional
            o_Functional_Lanes <= 2'b00;

            // Check upper 8 lanes (lanes 8–15)
            if (&i_Transmitter_initiated_Data_to_CLK_Result[15:8] &&
                &i_Transmitter_initiated_Data_to_CLK_Result[7:0]) begin
                o_Functional_Lanes <= 2'b11; // all lanes functional
            end else if (&i_Transmitter_initiated_Data_to_CLK_Result[15:8]) begin
                o_Functional_Lanes <= 2'b10; // upper group functional
            end else if (&i_Transmitter_initiated_Data_to_CLK_Result[7:0]) begin
                o_Functional_Lanes <= 2'b01; // lower group functional
            end

            // Signal setup completion (sticky until reset)
            done_setup <= 1'b1;
        end
    end

endmodule
