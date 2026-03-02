module SBINIT_WRAPPER
#(parameter SB_MSG_WIDTH = 4)
(
//clk and reset
input i_clk,
input i_rst_n,

//enable from ltsm
input i_SBINIT_en,

//from sb
input i_start_pattern_done, //yaane pattern sent done
input i_rx_msg_valid, //trust what came
input i_sb_busy,  // wrapper needs this to know if SB can accept
input [SB_MSG_WIDTH-1:0]i_decoded_SB_msg,
//to sb
output reg [SB_MSG_WIDTH-1:0] o_encoded_SB_msg,  // to SB (selected TX or RX)
output reg o_tx_msg_valid  ,   // to SB (selected valid)
output o_start_pattern_req,
//to ltsm
output o_SBINIT_end
);

// Internal Wires - TX_SBINIT outputs
wire [SB_MSG_WIDTH-1:0]     w_tx_encoded_msg;
wire                        w_tx_valid;   //TX_SBINIT tells wrapper it want to send data
wire                        w_tx_start_pattern_req;
wire                        w_tx_SBINIT_end;
    
// Internal Wires - RX_SBINIT outputs
wire [SB_MSG_WIDTH-1:0]     w_rx_encoded_msg;
wire                        w_rx_valid;
wire                        w_rx_SBINIT_end;

// Internal Wires - Ready signals from wrapper to TX/RX
wire w_tx_ready;
wire w_rx_ready;


  // SB ready
  wire sb_ready = ~i_sb_busy;

TX_SBINIT #(
    .SB_MSG_WIDTH(SB_MSG_WIDTH))
    U_TX_SBINIT (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),
    .i_SBINIT_en            (i_SBINIT_en),
    .i_start_pattern_done   (i_start_pattern_done),
    .i_rx_msg_valid         (i_rx_msg_valid),
    .i_sb_busy              (i_sb_busy),
    .i_tx_ready_tx          (w_tx_ready),
    .i_decoded_SB_msg       (i_decoded_SB_msg),
    .o_encoded_SB_msg_tx    (w_tx_encoded_msg),
    .o_start_pattern_req    (w_tx_start_pattern_req),
    .o_SBINIT_end_tx        (w_tx_SBINIT_end),
    .o_valid_tx             (w_tx_valid)
    );

RX_SBINIT #(
    .SB_MSG_WIDTH(SB_MSG_WIDTH))
        U_RX_SBINIT (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),
    .i_SBINIT_en            (i_SBINIT_en),
    .i_rx_msg_valid         (i_rx_msg_valid),
    .i_sb_busy              (i_sb_busy),
    .i_tx_ready_rx          (w_rx_ready),
    .i_decoded_SB_msg       (i_decoded_SB_msg),
    .o_encoded_SB_msg_rx    (w_rx_encoded_msg),
    .o_SBINIT_end_rx        (w_rx_SBINIT_end),
    .o_valid_rx             (w_rx_valid)
    );



  // Arbitration (rx priority)
  reg [1:0] grant;

  wire grant_tx = (grant == 2'b01);  //01 for tx
  wire grant_rx = (grant == 2'b10);  //10 for rx

  // fire happens when granted side has valid and SB is ready
  wire fire_tx = grant_tx && w_tx_valid && sb_ready;
  wire fire_rx = grant_rx && w_rx_valid && sb_ready;
  wire fire_any = fire_tx || fire_rx;


  // Grant logic
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      grant <= 2'b00;
    end else begin
      if (!i_SBINIT_en) begin
        grant <= 2'b00;
      end else begin
          if (grant == 2'b00) begin
          // choose new grant
          if (w_rx_valid)      grant <= 2'b10;  // RX priority
          else if (w_tx_valid) grant <= 2'b01;
          else              grant <= 2'b00;
        end else begin
          // keep it until message is accepted (fire)
          if (fire_any) grant <= 2'b00;
        end
      end
    end
  end

  // Ready back only if granted AND SB ready
  assign w_tx_ready = grant_tx && sb_ready;
  assign w_rx_ready = grant_rx && sb_ready;

//DRIVE OUTPUTS GOING TO SB
always @(*) begin
  if (grant_rx) begin
    o_encoded_SB_msg = w_rx_encoded_msg;
    o_tx_msg_valid   = w_rx_valid;
  end else if (grant_tx) begin
    o_encoded_SB_msg = w_tx_encoded_msg;
    o_tx_msg_valid   = w_tx_valid;
  end else begin
    o_encoded_SB_msg = 0;
    o_tx_msg_valid   = 0;
  end
end

  // start_pattern_req only from TX
  assign o_start_pattern_req = w_tx_start_pattern_req;

   //handling o_sbinit_end as for tx and rx they are pulses and shouldnt come at same time
    reg tx_done_seen, rx_done_seen;

always @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    tx_done_seen <= 1'b0;
    rx_done_seen <= 1'b0;
  end else if (!i_SBINIT_en) begin
    tx_done_seen <= 1'b0;
    rx_done_seen <= 1'b0;
  end else begin
    if (w_tx_SBINIT_end) tx_done_seen <= 1'b1;
    if (w_rx_SBINIT_end) rx_done_seen <= 1'b1;
  end
end

assign o_SBINIT_end = tx_done_seen & rx_done_seen;

endmodule