module mux_2_1 (
input [63:0] i_packet ,
input [63:0] i_pattern ,
input i_packet_valid,
input i_pattern_valid,

output reg [63:0] o_final_packet 

);

always @(*) begin
    if(i_pattern_valid)begin
        o_final_packet = i_pattern ;
    end 
    else if(i_packet_valid)begin
        o_final_packet = i_packet ;
    end 
    else begin
        o_final_packet = 64'b0 ;
    end 

end

endmodule 