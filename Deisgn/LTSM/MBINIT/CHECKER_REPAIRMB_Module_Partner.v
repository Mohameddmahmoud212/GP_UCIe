module CHECKER_REPAIRMB_Module_Partner (
    input               CLK,
    input               rst_n,
    input               i_start_check,
    input               i_second_check,
    input  [1:0]        i_Functional_Lanes,
    input               i_Transmitter_initiated_Data_to_CLK_en,
    output reg          o_done_check,
    output reg          o_go_to_repeat, 
    output reg          o_go_to_train_error,
    output reg          o_continue
);

    reg [1:0] prev_Functional_Lanes; // fixed width

    // Registering the Functional Lanes
    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n)
            prev_Functional_Lanes <= 2'b00;
        else if (i_start_check)
            prev_Functional_Lanes <= i_Functional_Lanes;
    end

    // Check Logic
    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n) begin
            o_done_check       <= 0;
            o_go_to_repeat     <= 0;
            o_go_to_train_error<= 0;
            o_continue         <= 0;
        end else if (i_start_check) begin
            o_done_check <= 1;

            if (i_second_check) begin
                if (i_Functional_Lanes != prev_Functional_Lanes) begin
                    o_go_to_train_error <= 1;
                    o_go_to_repeat     <= 0;
                    o_continue         <= 0;
                end else begin
                    o_go_to_train_error <= 0;
                    o_go_to_repeat     <= 0;
                    o_continue         <= 1;
                end
            end else if (~i_Transmitter_initiated_Data_to_CLK_en) begin
                case (i_Functional_Lanes)
                    2'b00: begin
                        o_go_to_train_error <= 1;
                        o_go_to_repeat     <= 0;
                        o_continue         <= 0;
                    end
                    2'b01, 2'b10: begin
                        o_go_to_train_error <= 0;
                        o_go_to_repeat     <= 1;
                        o_continue         <= 0;
                    end
                    2'b11: begin
                        o_go_to_train_error <= 0;
                        o_go_to_repeat     <= 0;
                        o_continue         <= 1;
                    end
                    default: begin
                        o_go_to_train_error <= 0;
                        o_go_to_repeat     <= 0;
                        o_continue         <= 0;
                    end
                endcase
            end else begin
                // Default when transmitter initiated data is enabled
                o_go_to_train_error <= 0;
                o_go_to_repeat     <= 0;
                o_continue         <= 0;
            end
        end else begin
            // Reset outputs when not checking
            o_done_check        <= 0;
            o_go_to_repeat      <= 0;
            o_go_to_train_error <= 0;
            o_continue          <= 0;
        end
    end

endmodule
