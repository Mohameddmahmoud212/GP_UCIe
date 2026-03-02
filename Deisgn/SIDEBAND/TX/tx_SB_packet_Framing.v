module SB_packetizer (
	input 				i_clk,
	input 				i_rst_n,
	input		[61:0]	i_header,
	input		[63:0]	i_data,
	input				i_header_done,  // header encoder 
	input 				i_d_valid,      // data encoder 
	input 				i_ser_done,     // serializer 
    input               i_frame_en,
    output              o_msg_with_data,
	output	reg	[63:0]	o_final_packet,
	output 	reg			o_timeout_ctr_start,
	output 	reg			o_packet_done
);

reg cp, dp;
reg cp_done, dp_done;
reg msg_with_data;
reg header_phase_sent;
reg [63:0]data ;


assign o_msg_with_data = msg_with_data ;
always @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		cp 			<= 0;
		cp_done 	<= 0;
	end 
	else if (i_header_done) begin
		cp 			<= ^i_header;
		cp_done 	<=	1;
	end
	else if (header_phase_sent) begin
		cp_done 	<= 0;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		dp 					<= 0;
		dp_done 			<= 0;
		msg_with_data 		<= 0;
        data                <= 0;
	end 
	else if (i_d_valid) begin
        data                <=  i_data;
		dp 					<= ^i_data;
		dp_done 			<=	1;
		if (|i_data ) begin
			msg_with_data 	<= 1;
		end
		else begin
			msg_with_data	<= 0;
		end
	end
	else if (header_phase_sent) begin
		dp_done 			<= 0;
		msg_with_data 		<= 0;
	end

end


always @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		o_final_packet 				<= 0;
		o_timeout_ctr_start			<= 0; 
		o_packet_done 				<= 0;
		header_phase_sent 			<= 0;
	end 
	else begin
        if(i_frame_en) begin
            /*if (o_packet_done) begin
                o_packet_done <= 0;
            end*/
            if (cp_done && (dp_done || !msg_with_data) && !header_phase_sent) begin
                o_final_packet 	<= {dp, cp, i_header}; 
                o_packet_done 			<= 1;
                header_phase_sent 		<= 1;
                if (i_header[17:14] == 5) begin // any req msg 
                    o_timeout_ctr_start		<= 1;
                end
            end
            else if (header_phase_sent && msg_with_data) begin
                o_final_packet 	        <= data;
                o_timeout_ctr_start		<= 0;
                header_phase_sent 		<= 0;
                o_packet_done 		  	<= 1;
            end
            else if (header_phase_sent && !msg_with_data) begin
                o_timeout_ctr_start		<= 0; 
                o_packet_done 			<= 0;
                header_phase_sent 		<= 0;
            end
            else begin
                o_timeout_ctr_start		<= 0; 
                o_packet_done 			<= 0;
                o_final_packet          <= 0;
            end
        end
        else begin
            o_final_packet 		        <= 0;
            o_timeout_ctr_start			<= 0; 
            o_packet_done 				<= 0;
            header_phase_sent 			<= 0;
        end 
        
    end
end 


endmodule 