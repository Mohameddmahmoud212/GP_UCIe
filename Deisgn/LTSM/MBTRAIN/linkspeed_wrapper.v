module linkspeed_wrapper (
        input  wire       clk,
        input  wire       rst_n,
        input  wire       i_en,
        // talking with sideband 
        input  wire [3:0] i_sideband_message,           
        input  wire       i_falling_edge_busy,
        input  wire       i_sideband_valid,
        // talking with point test block 
        input  wire       i_point_test_ack,
        input  wire [15:0] i_lanes_result,
        // still doesn't have a source 
        input  wire       i_valid_framing_error,
        // communicating with mbtrain controller 
        input  wire       i_first_8_tx_lanes_are_functional,
        input  wire       i_second_8_tx_lanes_are_functional,
        input  wire       i_comming_from_repair,
    //outputs
        // talking with sideband 
        output wire       o_valid,
        output wire [3:0] o_sideband_message,
        // talking with MBTRAIN fsm
        output wire       o_link_speeed_ack,
        // next state flags
        output wire       o_phy_retrain_req_was_sent_or_received,
        output wire       o_error_req_was_sent_or_received,
        output wire       o_speed_degrade_req_was_sent_or_received,
        output wire       o_repair_req_was_sent_or_received,
        // talking with phyretrain
        output wire [1:0] o_phyretrain_error_encoding,
        // talking with mbtrain controller (local lane status after PT / decision)
        output wire       o_local_first_8_lanes_are_functional,
        output wire       o_local_second_8_lanes_are_functional,
        // talking with point test 
        output wire       o_point_test_en
);

    /*------------------------------------------------------------------------------
    -- tx signals  
    ------------------------------------------------------------------------------*/
    wire [3:0] sb_msg_tx;
    wire       valid_tx;
    wire       ack_tx;
    wire       pt_en_tx;

    /*------------------------------------------------------------------------------
    -- rx signals   
    ------------------------------------------------------------------------------*/
    wire [3:0] sb_msg_rx;
    wire       valid_rx;
    wire       ack_rx;
    wire       pt_en_rx;
    reg tx_finish , rx_finish ;

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
    assign o_link_speeed_ack = tx_finish && rx_finish;

    // PT enable: UPDATE => OR (prevents deadlock)
    assign o_point_test_en   = pt_en_tx || pt_en_rx;

    // sideband valid OR
    assign o_valid           = valid_rx || valid_tx;

    // sideband message mux (TX priority like other wrappers)
    assign o_sideband_message =
        (valid_rx) ? sb_msg_rx :
        (valid_tx) ? sb_msg_tx :
                     4'b0000;

    /*------------------------------------------------------------------------------
    -- TX instantiation
    ------------------------------------------------------------------------------*/
    linkspeed_tx linkspeed_tx_inst(
        .clk                             (clk),
        .rst_n                           (rst_n),
        .i_en                            (i_en),

        .i_sideband_message              (i_sideband_message),
        .i_sideband_valid                (i_sideband_valid),

        .i_valid_rx                      (valid_rx),

        .i_busy_negedge_detected         (i_falling_edge_busy),

        .i_point_test_ack                (i_point_test_ack),
        .i_lanes_result                  (i_lanes_result),
        .i_valid_framing_error           (i_valid_framing_error),

        // communicating with mbtrain controller 
        .i_first_8_tx_lanes_are_functional (i_first_8_tx_lanes_are_functional),
        .i_second_8_tx_lanes_are_functional(i_second_8_tx_lanes_are_functional),
        .i_comming_from_repair            (i_comming_from_repair),

        // outputs
        .o_test_ack                      (ack_tx),
        .o_point_test_en                 (pt_en_tx),

        .o_sideband_message              (sb_msg_tx),
        .o_valid_tx                      (valid_tx),

        // next state flags
        .o_phy_retrain_req (o_phy_retrain_req_was_sent_or_received),
        .o_error_req       (o_error_req_was_sent_or_received),
        .o_speed_degrade_req(o_speed_degrade_req_was_sent_or_received),
        .o_repair_req      (o_repair_req_was_sent_or_received),

        // phy retrain encoding
        .o_phyretrain_error_encoding     (o_phyretrain_error_encoding),

        // local lane status
        .o_local_first_8_lanes_are_functional (o_local_first_8_lanes_are_functional),
        .o_local_second_8_lanes_are_functional(o_local_second_8_lanes_are_functional)
    );

    /*------------------------------------------------------------------------------
    -- RX instantiation
    ------------------------------------------------------------------------------*/
    linkspeed_rx linkspeed_rx_inst(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .i_en                   (i_en),

        .i_sideband_message      (i_sideband_message),
        .i_sideband_valid        (i_sideband_valid),

        .i_valid_tx              (valid_tx),
        .i_busy_negedge_detected (i_falling_edge_busy),

        .i_point_test_ack        (i_point_test_ack),
        .i_lanes_result          (i_lanes_result),
        .i_valid_framing_error   (i_valid_framing_error),

        // communicating with mbtrain controller 
        .i_first_8_tx_lanes_are_functional (i_first_8_tx_lanes_are_functional),
        .i_second_8_tx_lanes_are_functional(i_second_8_tx_lanes_are_functional),
        .i_comming_from_repair             (i_comming_from_repair),

        // outputs
        .o_sideband_message      (sb_msg_rx),
        .o_valid_rx              (valid_rx),
        .o_point_test_en         (pt_en_rx),
        .o_test_ack              (ack_rx)

    );

endmodule