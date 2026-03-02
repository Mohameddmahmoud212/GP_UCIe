module repair_wrapper (
    //inputs 
        //main signals
        input  wire        clk,
        input  wire        rst_n,
        input  wire        i_en,

        //communicating with sideband  (MATCH mbtrain_wrapper)
        input  wire [3:0]  i_sideband_message,
        input  wire        i_falling_edge_busy,
        input  wire        i_sideband_valid,        // UPDATE: added (you have it in mbtrain_wrapper)
        input  wire [2:0]  i_sideband_data_lanes_encoding,

        //communicating with linkspeed (MATCH mbtrain_wrapper intent)
        input  wire        i_first_8_lanes_are_functional,
        input  wire        i_second_8_lanes_are_functional,

    //outputs 
        //communicating with sideband
        output wire        o_valid,
        output wire [2:0]  o_sideband_data_lanes_encoding,
        output wire [3:0]  o_sideband_message,

        //returning results back to mbtrain
        output wire        o_remote_partner_first_8_lanes_result,
        output wire        o_remote_partner_second_8_lanes_result,

        //finishing ack
        output wire        o_test_ack
);

    // TX nets
    wire [3:0] sb_msg_tx;
    wire       valid_tx;
    wire       ack_tx;
    wire [2:0] enc_tx;
    reg        tx_finish , rx_finish;
    // RX nets
    wire [3:0] sb_msg_rx;
    wire       valid_rx;
    wire       ack_rx;
    wire       rem1_rx, rem2_rx;

    // unified valid
    assign o_valid = valid_tx || valid_rx;
    always @(posedge clk) begin
        if (ack_tx)
            tx_finish <= 1'b1 ;
        if (ack_rx)
            rx_finish <= 1'b1 ;
        
    end
    /*------------------------------------------------------------------------------
    -- combine outputs (UPDATED)
    ------------------------------------------------------------------------------*/
    // MBTRAIN FSM ack: keep your style (both ends must finish)
    assign o_test_ack = tx_finish && rx_finish;

    // sideband message mux (TX priority like all wrappers)
    assign o_sideband_message =
        (valid_rx) ? sb_msg_rx :
        (valid_tx) ? sb_msg_tx :
                     4'b0000;

    // our encoding to sideband-data path (TX decides)
    assign o_sideband_data_lanes_encoding = enc_tx;

    // remote partner results (RX decodes received encoding)
    assign o_remote_partner_first_8_lanes_result  = rem1_rx;
    assign o_remote_partner_second_8_lanes_result = rem2_rx;

   

    // ---------------- TX ----------------
    repair_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_sideband_message(i_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_falling_edge_busy),
        .i_valid_rx(valid_rx),

        .i_first_8_lanes_are_functional(i_first_8_lanes_are_functional),
        .i_second_8_lanes_are_functional(i_second_8_lanes_are_functional),

        .o_sideband_message(sb_msg_tx),
        .o_valid_tx(valid_tx),

        .o_sideband_data_lanes_encoding(enc_tx),
        .o_test_ack(ack_tx)
    );

    // ---------------- RX ----------------
    repair_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),

        .i_sideband_message(i_sideband_message),
        .i_sideband_valid(i_sideband_valid),

        .i_busy_negedge_detected(i_falling_edge_busy),
        .i_valid_tx(valid_tx),

        .i_sideband_data_lanes_encoding(i_sideband_data_lanes_encoding),

        .o_sideband_message(sb_msg_rx),
        .o_valid_rx(valid_rx),

        .o_remote_partner_first_8_lanes_result(rem1_rx),
        .o_remote_partner_second_8_lanes_result(rem2_rx),

        .o_test_ack(ack_rx)
    );

endmodule
