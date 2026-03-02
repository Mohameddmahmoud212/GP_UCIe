module CLOCK_CONTROLLER (
    input           i_clk,                  // Input clock from PLL (800 MHz)
    input           i_rst_n,                // Active-low reset
    input           i_enable,               // Enable that there is a packet want to be send to active clock
    output reg      o_iteration_finished,        // Indicates that packet serializing finished (level signal for 32 clock cycle)
    output reg      o_ser_ready,             // Indication that serializer finished serializing 64 bits (pulse level)
    output          TXCKSB                  // Gated clock output
);

/*------------------------------------------------------------------------------
-- INTERNAL WIRES & REGS   
------------------------------------------------------------------------------*/
reg [8:0] counter;           // Counter for 96 cycle to be repeated
reg clock_enable;            // Clock enable for 96 cycle (64 active and 32 sleep)
wire ser_en;                 // Enable for not gating the clock
reg ser_en_latched;          // Latched version of ser_en
reg dff1,dff2 ;
assign ser_en = ((dff1 || clock_enable) && counter < 9'd64); 
//output for serializer to send 64 bits 


/*------------------------------------------------------------------------------
-- Gated output clock
------------------------------------------------------------------------------*/

assign TXCKSB = (i_clk && ser_en_latched);  //

/*------------------------------------------------------------------------------
-- Latch for Clock Gating
------------------------------------------------------------------------------*/
always @(*) begin
    if (!i_clk) begin            // when  clk  = 0 
        ser_en_latched = ser_en; // Latch ser_en when clock is low
    end
end
/*------------------------------------------------------------------------------
-- Packet Serializing Finished Logic
------------------------------------------------------------------------------*/
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        counter <= 9'b0;
        o_iteration_finished <= 1;
        clock_enable <= 0;
        dff1<=0;
        dff2<=0;
    end 
    else begin
        dff1<=i_enable;
        dff2<=dff1 ;
    	if (dff1 || clock_enable) begin
    		clock_enable <= 1;
    		counter <= counter + 1;
            if(counter == 9'd94) begin
                o_iteration_finished <= 1;
                counter <= 9'b0;
                clock_enable <= 0;
            end 
            else begin
                o_iteration_finished <= 0;
            end 
                 
    	end  
    end
end

endmodule