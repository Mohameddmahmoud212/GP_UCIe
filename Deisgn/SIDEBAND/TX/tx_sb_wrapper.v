module sb_tx_wrapper (
input i_clk ,
input i_rst_n ,

// used for data and header encoder 
input i_data_valid,
input i_msg_valid,                  //yaane 3ndy message 3yza ttb3t f mhtag a3ml encode
input [3:0] i_state ,               //gyale ml ltsm ana f anhy state
input [3:0] i_sub_state,            //gyale ml ltsm ana f anhy substate
input [3:0]	i_msg_no,
input [2:0]	i_msg_info,
input i_tx_point_sweep_test_en,
input [1:0] i_tx_point_sweep_test,
input [15:0]i_data_bus,             // for data encoder 
input i_start_pattern_req ,         //from ltsm
input i_pattern_detected,           //### not sure , come from ? , handel in testbench for now 

output o_sb_busy,
output TXDATASB,  // final output from serializer
output o_pattern_time_out,
output TXCKSB 
// output o_pattern_done

);
    wire w_clk_div8 ;// divided clk 

    wire w_header_encoder_enable  ;//GAY MN al fsm to header encoder en 
    wire [61:0] w_header_message_encoded ;// wire to packet framing  and controller
    wire w_header_done ; 

    // for data encoder 
    wire [63:0] w_data_encoded ;
    wire  w_d_valid ;
    //serializer 
    //wire w_ser_ready ;

    wire [63:0]w_packet ;
    wire w_timeout_ctr_start ,w_packet_done ;
    wire w_start_pattern_done ;

    wire  w_pattern_valid ;
    wire [63:0] w_pattern , w_final_packet , w_data_fifo;
    
    wire w_enbale , w_read_enable , w_iteration_finished , w_data_valid;// enable for fifo
    wire w_busy , w_full ,w_data_encoder_enable , w_frame_en , w_start_pattern_req;
    /// addddd 
    wire w_clk_controller ,w_empty;
    reg r_iteration_finished ;
    
        assign w_enbale         = (w_packet_done || w_pattern_valid);
        assign w_read_enable    = (w_iteration_finished && !w_empty );
        assign w_clk_controller = (w_iteration_finished && !w_empty);
        
        
        sb_header_encoder header_d (
            .i_clk(w_clk_div8) ,
            .i_rst_n(i_rst_n) ,
            .i_data_valid(i_data_valid) ,
            .i_header_encoder_enable(w_header_encoder_enable),//wire 
            .i_msg_valid(i_msg_valid) ,
            .i_state(i_state) ,
            .i_sub_state(i_sub_state) ,
            .i_msg_info(i_msg_info) ,
            .i_msg_no(i_msg_no) ,
            .i_tx_point_sweep_test_en(i_tx_point_sweep_test_en) ,
            .i_tx_point_sweep_test(i_tx_point_sweep_test) ,

            .o_header_message_encoded(w_header_message_encoded) ,// wire to packet framing 
            .o_header_done(w_header_done) 
        );  


        data_encoder data_encoder_dut(
        .i_clk(w_clk_div8),
        .i_rst_n(i_rst_n),
        .i_data_valid(i_data_valid),
        .i_data_en(w_data_encoder_enable),
        .i_state(i_state),
        .i_sub_state(i_sub_state),
        .i_msg_no(i_msg_no),
        .i_data_bus(i_data_bus),
        .i_tx_point_sweep_test_en(i_tx_point_sweep_test_en),
        .i_tx_point_sweep_test(i_tx_point_sweep_test),

        .o_data_encoded(w_data_encoded),
        .o_d_valid(w_d_valid)
        );

        clk_div8 clk_divider_dut(
            .i_clk(i_clk),
            .i_rst_n(i_rst_n),

            .o_clk_div8(w_clk_div8)
        );
        

        SB_packetizer packetizer_dut(
            .i_clk(w_clk_div8),
            .i_rst_n(i_rst_n),
            .i_header(w_header_message_encoded),
            .i_data(w_data_encoded),
            .i_header_done(w_header_done),
            .i_d_valid(w_d_valid),
            .i_ser_done(w_iteration_finished), // come from serializer 
            .i_frame_en(w_frame_en),
            .o_msg_with_data(w_msg_with_data),
            .o_final_packet(w_packet),          // wire input for mux 
            .o_timeout_ctr_start(w_timeout_ctr_start),// wire input for timout 
            .o_packet_done(w_packet_done)             // wire input for mux and fsm
        );

        SB_PATTERN_GEN pattern_dut(

        .i_clk(w_clk_div8),
        .i_rst_n(i_rst_n),
        .i_start_pattern_req(w_start_pattern_req),
        .i_pattern_detected(i_pattern_detected),
        .i_ser_done(w_iteration_finished),

        .o_start_pattern_done(w_start_pattern_done),// input for controller 
        .o_pattern_time_out(o_pattern_time_out), // input for timeout only to make it time out 
        .o_pattern(w_pattern),              //64 bit pattern input for mux 
        .o_pattern_valid(w_pattern_valid)// input for mux 

        );


        mux_2_1 mux_d(
        .i_packet(w_packet),
        .i_pattern(w_pattern),
        .i_packet_valid(w_packet_done),
        .i_pattern_valid(w_pattern_valid),

        .o_final_packet(w_final_packet)

        );

                        

        SB_TX_FIFO FIFO_d(
            .i_clk(i_clk),
            .i_clk_div8(w_clk_div8),
            .i_rst_n(i_rst_n),
            .i_write_enable(w_enbale), 
            .i_read_enable(w_read_enable),          // not sure  serializer finish fifo not empty           
            .i_data_in(w_final_packet),
            

            .o_data_out(w_data_fifo),
            .o_empty(w_empty),                       // not sure 
            .o_ser_done_sampled(o_ser_done_sampled), // 
            .o_full(w_full),                          //
            .o_data_valid(w_data_valid)
        );

        sb_tx_serializer seri_d(
            .i_clk(i_clk),
            .i_rst_n(i_rst_n),
            .i_data(w_data_fifo),
            .i_enable(w_clk_controller),
            .i_data_valid(w_data_valid),
            
            .TXDATASB(TXDATASB),
            .o_busy(w_busy)  
            //.o_ser_ready(w_ser_ready)
        );
        sb_controller_tx controller_dut(
        .i_clk(w_clk_div8),
        .i_rst_n(i_rst_n),
        .i_start_pattern_req(i_start_pattern_req),
        .i_start_pattern_done(w_start_pattern_done),
        .i_msg_valid(i_msg_valid),
        .i_data_valid(i_data_valid),
        .i_header_done(w_header_done),
        .i_data_done(w_d_valid),
        .i_packet_done(w_packet_done),
        .i_SB_busy(w_busy),
        .i_fifo_empty(w_empty),
        .i_fifo_full(w_full),
        .i_iteration_finished(w_iteration_finished),
        .i_msg_with_data(w_msg_with_data),

        .o_header_encoder_enable(w_header_encoder_enable),
        .o_data_encoder_enable(w_data_encoder_enable),
        .o_frame_enable(w_frame_en),
        .o_pattern_enable(w_start_pattern_req),
        .o_sb_busy(o_sb_busy)

        );

        CLOCK_CONTROLLER out_clk_dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_enable(w_clk_controller),

        .o_iteration_finished(w_iteration_finished),
        .TXCKSB(TXCKSB)
        );
    

endmodule 