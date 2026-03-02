module mbtrain_controller (
    //inputs
        //main control signals
        input clk,
        input rst_n,
        input i_en,
        //input signal from phyretrain after resolving
        input [2:0] i_phyretrain_resolved_state,
        //input signal from mbinit
        input [2:0] i_highest_common_speed,
        input       i_first_8_tx_lanes_are_functional_mbinit , i_second_8_tx_lanes_are_functional_mbinit,
        input       i_first_8_rx_lanes_are_functional_mbinit , i_second_8_rx_lanes_are_functional_mbinit,
        //talking with linkspeed and repair
        input       i_first_8_tx_lanes_are_functional_linkspeed , i_second_8_tx_lanes_are_functional_linkspeed,
        input       i_first_8_rx_lanes_are_functional_repair    , i_second_8_rx_lanes_are_functional_repair,
        //next state flags
        input       i_phy_retrain_req_was_sent_or_received,   i_error_req_was_sent_or_received,
                    i_speed_degrade_req_was_sent_or_received, i_repair_req_was_sent_or_received,
        //enable for each substate (ACKs from substates)
        input  i_valvref_ack             , i_data_vref_ack        , i_speed_idle_ack             , i_tx_self_cal_ack   ,
        input  i_rx_clk_cal_ack          , i_val_train_center_ack , i_val_train_vref_ack         , i_data_train_center_1_ack   ,
        input  i_data_train_vref_ack     , i_rx_deskew_ack        , i_data_train_center_2_ack    , i_link_speed_ack , i_repair_ack ,

    //outputs
        //enable for each substate
        output reg  o_valvref_en            , o_data_vref_en        , o_speed_idle_en             , o_tx_self_cal_en   ,
        output reg  o_rx_clk_cal_en         , o_val_train_center_en , o_val_train_vref_en         , o_data_train_center_1_en   ,
        output reg  o_data_train_vref_en    , o_rx_deskew_en        , o_data_train_center_2_en    , o_link_speed_en , o_repair_en ,
        //deciding what to test main band or valid lane
        output reg  o_mainband_or_valtrain_test,
        //phy_retrain_enable
        output reg  o_phyretrain_en ,
        //communicating with sideband
        output reg [3:0] o_sideband_substate ,
        //communicating with pattern generators and detectors
        output reg       o_first_8_tx_lanes_are_functional , o_second_8_tx_lanes_are_functional,
        output reg       o_first_8_rx_lanes_are_functional , o_second_8_rx_lanes_are_functional,
        //mux sele
        output reg [2:0] o_mux_sel, //000 vref cal 001 selfcal 010 linkspeed 011 repair 100 train center 101 rx cal
        //finishing ack
        output reg o_mbtrain_ack,
        //communicating with linkspeed to tell it that a repair was done
        output o_comming_from_repair ,
        //communicating with pll
        output reg [2:0] o_curret_operating_speed
);

/*------------------------------------------------------------------------------
-- FSM States
------------------------------------------------------------------------------*/
// --------------------------------------------------
// MBTRAIN FSM STATES (clean, unique, ordered)
// --------------------------------------------------
parameter IDLE                 = 6'd0;

// VREF calibration
parameter VALVREF              = 6'd1;
parameter VALVREF_END          = 6'd2;
parameter DATAVREF             = 6'd3;
parameter DATAVREF_END         = 6'd4;

// Speed idle
parameter SPEED_IDLE           = 6'd5;
parameter SPEED_IDLE_END       = 6'd6;

// TX self calibration
parameter TXSELFCAL            = 6'd7;
parameter TXSELFCAL_END        = 6'd8;

// RX clock calibration
parameter RXCLKCAL             = 6'd9;
parameter RXCLKCAL_END         = 6'd10;

// Validation training
parameter VALTRAINCENTER       = 6'd11;
parameter VALTRAINCENTER_END   = 6'd12;
parameter VALTRAINVREF         = 6'd13;
parameter VALTRAINVREF_END     = 6'd14;

// Data training
parameter DATATRAINCENTER1     = 6'd15;
parameter DATATRAINCENTER1_END = 6'd16;
parameter DATATRAINVREF        = 6'd17;
parameter DATATRAINVREF_END    = 6'd18;

// RX deskew
parameter RXDESKEW             = 6'd19;
parameter RXDESKEW_END         = 6'd20;

// Data train center 2
parameter DATATRAINCENTER2     = 6'd21;
parameter DATATRAINCENTER2_END = 6'd22;

// Link speed & repair
parameter LINKSPEED            = 6'd23;
parameter LINKSPEED_END        = 6'd24;
parameter REPAIR               = 6'd25;
parameter REPAIR_END           = 6'd26;

// Finish
parameter MBTRAIN_FINISH       = 6'd27;


/*------------------------------------------------------------------------------
-- Variables Declaration
------------------------------------------------------------------------------*/
reg [5:0] cs, ns; // widened due to added states

// handle the case that we enter linkspeed and there was a repair done before
reg repiar_was_done_in_mbinit;
reg repiar_was_done_in_mbtrain;

/*------------------------------------------------------------------------------
-- assign statements
------------------------------------------------------------------------------*/
assign o_comming_from_repair = repiar_was_done_in_mbinit || repiar_was_done_in_mbtrain;

/*------------------------------------------------------------------------------
-- Current State Update
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_cs
    if (~rst_n) cs <= IDLE;
    else        cs <= ns;
end

/*------------------------------------------------------------------------------
-- Next State Logic
------------------------------------------------------------------------------*/
always @(*) begin
    ns = cs; // default
    case (cs)
        IDLE: begin
            if (i_en) begin
                case (i_phyretrain_resolved_state)
                    3'b001: ns = TXSELFCAL;
                    3'b100: ns = REPAIR;
                    3'b010: ns = SPEED_IDLE;
                    default: ns = IDLE;
                endcase
            end else begin
                ns = IDLE;
            end
        end

        VALVREF: begin
            if (i_valvref_ack) ns = VALVREF_END;
            else               ns = VALVREF;
        end

        VALVREF_END: begin
            if (~i_valvref_ack) ns = DATAVREF;
            else                ns = VALVREF_END;
        end

        // DATAVREF now has END state (non-optional)
        DATAVREF: begin
            if (i_data_vref_ack) ns = DATAVREF_END;
            else                 ns = DATAVREF;
        end

        DATAVREF_END: begin
            if (~i_data_vref_ack) ns = SPEED_IDLE;
            else                  ns = DATAVREF_END;
        end

        SPEED_IDLE: begin
            if (i_speed_idle_ack) ns = SPEED_IDLE_END;
            else                  ns = SPEED_IDLE;
        end

        SPEED_IDLE_END: begin
            if (~i_speed_idle_ack) ns = TXSELFCAL;
            else                   ns = SPEED_IDLE_END;
        end

        TXSELFCAL: begin
            if (i_tx_self_cal_ack) ns = TXSELFCAL_END;
            else                   ns = TXSELFCAL;
        end

        TXSELFCAL_END: begin
            if (~i_tx_self_cal_ack) ns = RXCLKCAL;
            else                    ns = TXSELFCAL_END;
        end

        RXCLKCAL: begin
            if (i_rx_clk_cal_ack) ns = RXCLKCAL_END;
            else                  ns = RXCLKCAL;
        end

        RXCLKCAL_END: begin
            if (~i_rx_clk_cal_ack) ns = VALTRAINCENTER;
            else                   ns = RXCLKCAL_END;
        end

        VALTRAINCENTER: begin
            if (i_val_train_center_ack) ns = VALTRAINCENTER_END;
            else                        ns = VALTRAINCENTER;
        end

        VALTRAINCENTER_END: begin
            if (~i_val_train_center_ack) ns = VALTRAINVREF;
            else                         ns = VALTRAINCENTER_END;
        end

        VALTRAINVREF: begin
            if (i_val_train_vref_ack) ns = VALTRAINVREF_END;
            else                      ns = VALTRAINVREF;
        end

        VALTRAINVREF_END: begin
            if (~i_val_train_vref_ack) ns = DATATRAINCENTER1;
            else                       ns = VALTRAINVREF_END;
        end

        DATATRAINCENTER1: begin
            if (i_data_train_center_1_ack) ns = DATATRAINCENTER1_END;
            else                           ns = DATATRAINCENTER1;
        end

        DATATRAINCENTER1_END: begin
            if (~i_data_train_center_1_ack) ns = DATATRAINVREF;
            else                            ns = DATATRAINCENTER1_END;
        end

        DATATRAINVREF: begin
            if (i_data_train_vref_ack) ns = DATATRAINVREF_END;
            else                       ns = DATATRAINVREF;
        end

        DATATRAINVREF_END: begin
            if (~i_data_train_vref_ack) ns = RXDESKEW;
            else                        ns = DATATRAINVREF_END;
        end

        RXDESKEW: begin
            if (i_rx_deskew_ack) ns = RXDESKEW_END;
            else                 ns = RXDESKEW;
        end

        RXDESKEW_END: begin
            if (~i_rx_deskew_ack) ns = DATATRAINCENTER2;
            else                  ns = RXDESKEW_END;
        end

        // FIX + CONSISTENCY: use i_data_train_center_2_ack, and add END state
        DATATRAINCENTER2: begin
            if (i_data_train_center_2_ack) ns = DATATRAINCENTER2_END;
            else                           ns = DATATRAINCENTER2;
        end

        DATATRAINCENTER2_END: begin
            if (~i_data_train_center_2_ack) ns = LINKSPEED;
            else                            ns = DATATRAINCENTER2_END;
        end

        LINKSPEED: begin
            if (i_link_speed_ack) begin
                // priority:
                if (i_phy_retrain_req_was_sent_or_received) begin
                    ns = MBTRAIN_FINISH;
                end else if (i_error_req_was_sent_or_received) begin
                    if (i_speed_degrade_req_was_sent_or_received) ns = SPEED_IDLE;
                    else                                          ns = REPAIR;
                end else begin
                    ns = MBTRAIN_FINISH;
                end
            end else begin
                ns = LINKSPEED;
            end
        end

        REPAIR: begin
            if (i_repair_ack) ns = TXSELFCAL;
            else              ns = REPAIR;
        end

        MBTRAIN_FINISH: begin
            if (!i_en) ns = IDLE;
            else       ns = MBTRAIN_FINISH;
        end

        default: ns = IDLE;
    endcase
end

/*------------------------------------------------------------------------------
-- Output Logic
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_output
    if (~rst_n) begin
        o_valvref_en                 <= 0;
        o_data_vref_en               <= 0;
        o_speed_idle_en              <= 0;
        o_tx_self_cal_en             <= 0;
        o_rx_clk_cal_en              <= 0;
        o_val_train_center_en        <= 0;
        o_val_train_vref_en          <= 0;
        o_data_train_center_1_en     <= 0;
        o_data_train_vref_en         <= 0;
        o_rx_deskew_en               <= 0;
        o_data_train_center_2_en     <= 0;
        o_link_speed_en              <= 0;
        o_repair_en                  <= 0;

        o_mainband_or_valtrain_test  <= 0;

        o_phyretrain_en              <= 0;   // ADDED reset
        o_sideband_substate          <= 0;   // ADDED reset
        o_mux_sel                    <= 0;   // ADDED reset

        o_mbtrain_ack                <= 0;

        repiar_was_done_in_mbtrain   <= 0;
    end
    else begin
        case (cs)
            IDLE: begin
                // default low
                o_valvref_en                 <= 0;
                o_data_vref_en               <= 0;
                o_speed_idle_en              <= 0;
                o_tx_self_cal_en             <= 0;
                o_rx_clk_cal_en              <= 0;
                o_val_train_center_en        <= 0;
                o_val_train_vref_en          <= 0;
                o_data_train_center_1_en     <= 0;
                o_data_train_vref_en         <= 0;
                o_rx_deskew_en               <= 0;
                o_data_train_center_2_en     <= 0;
                o_link_speed_en              <= 0;
                o_repair_en                  <= 0;
                o_mbtrain_ack                <= 0;
                repiar_was_done_in_mbtrain   <= 0;
                o_phyretrain_en              <= 0;

                if (ns == VALVREF) begin
                    o_valvref_en                <= 1;
                    o_sideband_substate         <= 0;
                    o_mux_sel                   <= 3'b000;
                    o_mainband_or_valtrain_test <= 1;
                end else if (ns == TXSELFCAL) begin
                    o_tx_self_cal_en            <= 1;
                    o_sideband_substate         <= 3;
                    o_mux_sel                   <= 3'b001;
                end else if (ns == REPAIR) begin
                    o_repair_en                 <= 1;
                    o_link_speed_en             <= 0;
                    o_sideband_substate         <= 12;
                    o_mux_sel                   <= 3'b011;
                    repiar_was_done_in_mbtrain  <= 1;
                end else if (ns == SPEED_IDLE) begin
                    o_speed_idle_en             <= 1;
                    o_sideband_substate         <= 2;
                    o_mux_sel                   <= 3'b001;
                end else begin
                    o_sideband_substate         <= 0;
                    o_mux_sel                   <= o_mux_sel;
                end
            end

            VALVREF: begin
                if (ns == VALVREF_END) begin
                    o_valvref_en <= 0;
                end
            end

            VALVREF_END: begin
                if (ns == DATAVREF) begin
                    o_data_vref_en              <= 1;
                    o_sideband_substate         <= 1;
                    o_mux_sel                   <= 3'b000;
                    o_mainband_or_valtrain_test <= 0;
                end
            end

            DATAVREF: begin
                if (ns == DATAVREF_END) begin
                    o_data_vref_en <= 0; // turn off when moving to END state
                end
            end

            DATAVREF_END: begin
                if (ns == SPEED_IDLE) begin
                    o_speed_idle_en      <= 1;
                    o_sideband_substate  <= 2;
                    o_mux_sel            <= 3'b001;
                end
            end

            SPEED_IDLE: begin
                if (ns == SPEED_IDLE_END) begin
                    o_speed_idle_en <= 0;
                end
            end

            SPEED_IDLE_END: begin
                if (ns == TXSELFCAL) begin
                    o_tx_self_cal_en     <= 1;
                    o_sideband_substate  <= 3;
                    o_mux_sel            <= 3'b001;
                end
            end

            TXSELFCAL: begin
                if (ns == TXSELFCAL_END) begin
                    o_tx_self_cal_en <= 0;
                end
            end

            TXSELFCAL_END: begin
                if (ns == RXCLKCAL) begin
                    o_rx_clk_cal_en      <= 1;
                    o_sideband_substate  <= 4;
                    o_mux_sel            <= 3'b101;
                end
            end

            RXCLKCAL: begin
                if (ns == RXCLKCAL_END) begin
                    o_rx_clk_cal_en <= 0;
                end
            end

            RXCLKCAL_END: begin
                if (ns == VALTRAINCENTER) begin
                    o_val_train_center_en       <= 1;
                    o_sideband_substate         <= 5;
                    o_mux_sel                   <= 3'b100;
                    o_mainband_or_valtrain_test <= 1;
                end
            end

            VALTRAINCENTER: begin
                if (ns == VALTRAINCENTER_END) begin
                    o_val_train_center_en <= 0;
                end
            end

            VALTRAINCENTER_END: begin
                if (ns == VALTRAINVREF) begin
                    o_val_train_vref_en         <= 1;
                    o_sideband_substate         <= 6;
                    o_mux_sel                   <= 3'b000;
                    o_mainband_or_valtrain_test <= 1;
                end
            end

            VALTRAINVREF: begin
                if (ns == VALTRAINVREF_END) begin
                    o_val_train_vref_en <= 0;
                end
            end

            VALTRAINVREF_END: begin
                if (ns == DATATRAINCENTER1) begin
                    o_data_train_center_1_en    <= 1;
                    o_sideband_substate         <= 7;
                    o_mux_sel                   <= 3'b100;
                    o_mainband_or_valtrain_test <= 0;
                end
            end

            DATATRAINCENTER1: begin
                if (ns == DATATRAINCENTER1_END) begin
                    o_data_train_center_1_en <= 0;
                end
            end

            DATATRAINCENTER1_END: begin
                if (ns == DATATRAINVREF) begin
                    o_data_train_vref_en        <= 1;
                    o_sideband_substate         <= 8;
                    o_mux_sel                   <= 3'b000;
                    o_mainband_or_valtrain_test <= 0;
                end
            end

            DATATRAINVREF: begin
                if (ns == DATATRAINVREF_END) begin
                    o_data_train_vref_en <= 0;
                end
            end

            DATATRAINVREF_END: begin
                if (ns == RXDESKEW) begin
                    o_rx_deskew_en       <= 1;
                    o_sideband_substate  <= 9;
                    o_mux_sel            <= 3'b101;
                end
            end

            RXDESKEW: begin
                if (ns == RXDESKEW_END) begin
                    o_rx_deskew_en <= 0;
                end
            end

            RXDESKEW_END: begin
                if (ns == DATATRAINCENTER2) begin
                    o_data_train_center_2_en    <= 1;
                    o_sideband_substate         <= 10;
                    o_mux_sel                   <= 3'b100;
                    o_mainband_or_valtrain_test <= 0;
                end
            end

            DATATRAINCENTER2: begin
                if (ns == DATATRAINCENTER2_END) begin
                    o_data_train_center_2_en <= 0; // off in END
                end
            end

            DATATRAINCENTER2_END: begin
                if (ns == LINKSPEED) begin
                    o_link_speed_en       <= 1;
                    o_sideband_substate   <= 11;
                    o_mux_sel             <= 3'b010;
                    o_mainband_or_valtrain_test <= 0;
                end
            end

            LINKSPEED: begin
                // transitions out of linkspeed
                if (ns == REPAIR) begin
                    o_repair_en                <= 1;
                    o_link_speed_en            <= 0;
                    o_sideband_substate        <= 12;
                    o_mux_sel                  <= 3'b011;
                    repiar_was_done_in_mbtrain <= 1;
                end else if (ns == TXSELFCAL) begin
                    o_tx_self_cal_en     <= 1;
                    o_link_speed_en      <= 0;
                    o_sideband_substate  <= 3;
                    o_mux_sel            <= 3'b001;
                end else if (ns == SPEED_IDLE) begin
                    o_speed_idle_en      <= 1;
                    o_link_speed_en      <= 0;
                    o_sideband_substate  <= 2;
                    o_mux_sel            <= 3'b001;
                end else if (ns == MBTRAIN_FINISH) begin
                    o_link_speed_en      <= 0;
                    o_sideband_substate  <= 0;
                end

                // controlling phyretrain
                if (ns == MBTRAIN_FINISH && i_phy_retrain_req_was_sent_or_received)
                    o_phyretrain_en <= 1;
                else
                    o_phyretrain_en <= 0;
            end

            REPAIR: begin
                if (ns == TXSELFCAL) begin
                    o_tx_self_cal_en     <= 1;
                    o_repair_en          <= 0;
                    o_sideband_substate  <= 3; // tx self cal encoding
                    o_mux_sel            <= 3'b001;
                end
            end

            MBTRAIN_FINISH: begin
                o_mbtrain_ack <= 1;
            end

            default: begin
                // keep registered outputs stable by default
            end
        endcase
    end
end

/*------------------------------------------------------------------------------
-- handling current operating speed
-- FIX (non-optional): only decrement on SPEED_DEGRADE transition into SPEED_IDLE
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_o_curret_operating_speed
    if (~rst_n) begin
        o_curret_operating_speed <= 0;
    end
    else if (cs == IDLE && ns == VALVREF) begin
        o_curret_operating_speed <= i_highest_common_speed;
    end
    else if ((cs == LINKSPEED || cs == IDLE) &&
             ns == SPEED_IDLE &&
             i_speed_degrade_req_was_sent_or_received) begin
        o_curret_operating_speed <= o_curret_operating_speed - 1;
    end
end

/*------------------------------------------------------------------------------
-- handling widths of the tx and rx lanes
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_lane_widths
    if (~rst_n) begin
        o_first_8_tx_lanes_are_functional  <= 0;
        o_second_8_tx_lanes_are_functional <= 0;
        o_first_8_rx_lanes_are_functional  <= 0;
        o_second_8_rx_lanes_are_functional <= 0;
    end
    else if (cs == IDLE && ns == VALVREF) begin
        o_first_8_tx_lanes_are_functional  <= i_first_8_tx_lanes_are_functional_mbinit;
        o_second_8_tx_lanes_are_functional <= i_second_8_tx_lanes_are_functional_mbinit;
        o_first_8_rx_lanes_are_functional  <= i_first_8_rx_lanes_are_functional_mbinit;
        o_second_8_rx_lanes_are_functional <= i_second_8_rx_lanes_are_functional_mbinit;
    end
    else if (cs == LINKSPEED && ns != LINKSPEED) begin
        // TX results after point test
        o_first_8_tx_lanes_are_functional  <= i_first_8_tx_lanes_are_functional_linkspeed;
        o_second_8_tx_lanes_are_functional <= i_second_8_tx_lanes_are_functional_linkspeed;
    end
    else if (cs == REPAIR && ns != REPAIR) begin
        o_first_8_rx_lanes_are_functional  <= i_first_8_rx_lanes_are_functional_repair;
        o_second_8_rx_lanes_are_functional <= i_second_8_rx_lanes_are_functional_repair;
    end
end

/*------------------------------------------------------------------------------
-- handling repair was done signals
------------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin : proc_repair_was_done_in_mbinit
    if (~rst_n) begin
        repiar_was_done_in_mbinit <= 0;
    end
    else if (cs == IDLE && ns == VALVREF &&
            (~i_first_8_tx_lanes_are_functional_mbinit || ~i_second_8_tx_lanes_are_functional_mbinit)) begin
        repiar_was_done_in_mbinit <= 1;
    end
    else if (cs == MBTRAIN_FINISH) begin
        repiar_was_done_in_mbinit <= 0;
    end
end

endmodule
