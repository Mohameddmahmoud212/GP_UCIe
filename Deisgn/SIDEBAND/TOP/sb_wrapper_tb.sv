module sb_wrapper_tb;

//TX DIE0
reg die0_i_clk ;
reg die0_i_rst_n ;
reg die0_i_data_valid;
reg die0_i_msg_valid;                 
reg [3:0] die0_i_state ;              
reg [3:0] die0_i_sub_state;          
reg [3:0]	die0_i_msg_no;
reg [2:0]	die0_i_msg_info;
reg die0_i_tx_point_sweep_test_en;
reg [1:0] die0_i_tx_point_sweep_test;
reg [15:0] die0_i_data_bus;             
reg die0_i_start_pattern_req ;      
reg die0_i_pattern_detected;          

wire die0_o_sb_busy;
wire die0_TXDATASB;  
wire die0_o_pattern_time_out;
wire die0_TXCKSB; 


// RX pins should be wires if they are driven by assigns
wire die0_RXCKSB,  die0_RXDATASB;
wire die1_RXCKSB,  die1_RXDATASB;
wire die1_TXCKSB,  die1_TXDATASB;

// Cross-die interconnect (the "package/bridge" link)
assign die1_RXCKSB   = die0_TXCKSB;
assign die1_RXDATASB = die0_TXDATASB;


assign die0_RXCKSB   = die1_TXCKSB;
assign die0_RXDATASB = die1_TXDATASB;




wire          die0_o_tx_point_sweep_test_en;
wire  [1:0]   die0_o_tx_point_sweep_test;
//wire          die0_o_rx_sb_start_pattern;
wire          die0_o_msg_valid;
wire  [3:0]   die0_o_msg_no;
wire  [2:0]   die0_o_msg_info;
wire  [15:0]  die0_o_data;
wire          die0_o_sb_pattern_detect_done_rx;


//TX DIE1
reg die1_i_clk ;
reg die1_i_rst_n ;
reg die1_i_data_valid;
reg die1_i_msg_valid;                 
reg [3:0] die1_i_state ;              
reg [3:0] die1_i_sub_state;          
reg [3:0]	die1_i_msg_no;
reg [2:0]	die1_i_msg_info;
reg die1_i_tx_point_sweep_test_en;
reg [1:0] die1_i_tx_point_sweep_test;
reg [15:0] die1_i_data_bus;             
reg die1_i_start_pattern_req ;      
reg die1_i_pattern_detected;          

wire die1_o_sb_busy;
wire die1_o_pattern_time_out;

//RX DIE0


wire            die1_o_tx_point_sweep_test_en;
wire  [1:0]     die1_o_tx_point_sweep_test;
//wire            die1_o_rx_sb_start_pattern;
wire            die1_o_msg_valid;
wire  [3:0]     die1_o_msg_no;
wire  [2:0]     die1_o_msg_info;
wire  [15:0]    die1_o_data;
wire            die1_o_sb_pattern_detect_done_rx;



//local params
localparam SBINIT     = 0;
localparam MBINIT     = 1;
localparam MBTRAIN    = 2;
localparam PHYRETRAIN = 3;
localparam TRAINERROR = 4; //not implemented yet

//substates of mbinit
localparam PARAM 		 			= 0;
localparam CAL 			 			= 1;
localparam REPAIRCLK 		 		= 2;
localparam REPAIRVAL 		 		= 3;
localparam REVERSALMB 		 		= 4;
localparam REPAIRMB 			 	= 5;

//substates of mbtrain
localparam VALREF 		 			= 0;
localparam DATAVREF 	 			= 1;
localparam SPEEDIDLE  				= 2;
localparam TXSELFCAL 		 		= 3;
localparam RXCLKCAL 				= 4;
localparam VALTRAINCENTER 		 	= 5;
localparam VALTRAINVREF 			= 6;
localparam DATATRAINCENTER1 		= 7;
localparam DATATRAINVREF 			= 8;
localparam RXDESKEW 				= 9;
localparam DATATRAINCENTER2 		= 10;
localparam LINKSPEED 				= 11;
localparam REPAIR 					= 12;


sb_wrapper die0_dut(
    .i_clk(die0_i_clk),
    .i_rst_n(die0_i_rst_n),
    // msgs from ltsm 
    .i_data_valid(die0_i_data_valid),
    .i_msg_valid(die0_i_msg_valid),
    .i_state(die0_i_state),
    .i_sub_state(die0_i_sub_state),
    .i_msg_no(die0_i_msg_no),
    .i_msg_info(die0_i_msg_info),
    .i_tx_point_sweep_test_en(die0_i_tx_point_sweep_test_en),
    .i_tx_point_sweep_test(die0_i_tx_point_sweep_test),
    .i_data_bus(die0_i_data_bus),
    .i_start_pattern_req(die0_i_start_pattern_req),
    .i_pattern_detected(die0_i_pattern_detected),

    .RXCKSB(die0_RXCKSB),
    .RXDATASB(die0_RXDATASB),

    .o_sb_busy(die0_o_sb_busy),
    .TXDATASB(die0_TXDATASB),
    .o_pattern_time_out(die0_o_pattern_time_out),
    .TXCKSB(die0_TXCKSB),// output clk from die0

    .o_tx_point_sweep_test_en(die0_o_tx_point_sweep_test_en),
    .o_tx_point_sweep_test(die0_o_tx_point_sweep_test),
    .o_msg_valid(die0_o_msg_valid),
    .o_msg_no(die0_o_msg_no),
    .o_msg_info(die0_o_msg_info),
    .o_data(die0_o_data),
    .o_sb_pattern_detect_done_rx(die0_o_sb_pattern_detect_done_rx)   
);

sb_wrapper die1_dut(
    .i_clk(die1_i_clk),
    .i_rst_n(die1_i_rst_n),
    // msgs from ltsm 
    .i_data_valid(die1_i_data_valid),
    .i_msg_valid(die1_i_msg_valid),
    .i_state(die1_i_state),
    .i_sub_state(die1_i_sub_state),
    .i_msg_no(die1_i_msg_no),
    .i_msg_info(die1_i_msg_info),
    .i_tx_point_sweep_test_en(die1_i_tx_point_sweep_test_en),
    .i_tx_point_sweep_test(die1_i_tx_point_sweep_test),
    .i_data_bus(die1_i_data_bus),
    .i_start_pattern_req(die1_i_start_pattern_req),
    .i_pattern_detected(die1_i_pattern_detected),

    .RXCKSB(die1_RXCKSB),
    .RXDATASB(die1_RXDATASB),

    .o_sb_busy(die1_o_sb_busy),
    .TXDATASB(die1_TXDATASB),
    .o_pattern_time_out(die1_o_pattern_time_out),
    .TXCKSB(die1_TXCKSB),
    .o_tx_point_sweep_test_en(die1_o_tx_point_sweep_test_en),
    .o_tx_point_sweep_test(die1_o_tx_point_sweep_test),
    .o_msg_valid(die1_o_msg_valid),
    .o_msg_no(die1_o_msg_no),
    .o_msg_info(die1_o_msg_info),
    .o_data(die1_o_data),
    .o_sb_pattern_detect_done_rx(die1_o_sb_pattern_detect_done_rx)   
);


//clock die 0
initial begin
    die0_i_clk = 0;
    forever begin
        #625 die0_i_clk = ~die0_i_clk;
    end    
end

//clock die 1
initial begin
    die1_i_clk = 0;
    forever begin
        #625 die1_i_clk = ~die1_i_clk;
    end    
end

task wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            @(negedge die0_i_clk);
        end
    end
endtask

task reset_n;
    die0_i_rst_n = 0;
    die1_i_rst_n = 0;
    wait_cycles(5);
    die0_i_rst_n = 1;
    die1_i_rst_n = 1;    
endtask


task reset_all_inputs;

     //1 reset all inputs die 0
     die0_i_data_valid=0;
     die0_i_msg_valid=0;                 
     die0_i_state =0;              
     die0_i_sub_state=0;          
     die0_i_msg_no=0;
     die0_i_msg_info=0;
     die0_i_tx_point_sweep_test_en=0;
     die0_i_tx_point_sweep_test=0;
     die0_i_data_bus=0;             
     die0_i_start_pattern_req=0;      
     die0_i_pattern_detected=0; 

     //2 reset all inputs die 1
    
    die1_i_data_valid = 0;
    die1_i_msg_valid = 0;                 
    die1_i_state =0;              
    die1_i_sub_state  = 0;          
    die1_i_msg_no = 0;
    die1_i_msg_info = 0;
    die1_i_tx_point_sweep_test_en = 0;
    die1_i_tx_point_sweep_test =0 ;
    die1_i_data_bus = 0;             
    die1_i_start_pattern_req = 0;      
    die1_i_pattern_detected = 0;   


endtask

initial begin
    reset_all_inputs();
    reset_n();
    die0_i_start_pattern_req = 1;
    wait_cycles(2);
    die0_i_start_pattern_req = 0;

    wait_cycles(70);
    die0_i_pattern_detected = 1;
    wait_cycles(5);
    die0_i_data_valid = 0;
    die0_i_msg_valid  = 1;                 
    die0_i_state = 0;          
    die0_i_msg_no = 0 ;
    die0_i_msg_info = 0;
    wait_cycles(10);
    die0_i_msg_valid  = 0;  
    wait_cycles(100);
    $stop;
    $finish;
    
end
initial begin
    $monitor("time=%0t deser_done=%b deser_data=%h",
             $time,
             die1_dut.RX_WRAPPER_dut.w_de_ser_done,
             die1_dut.RX_WRAPPER_dut.w_deser_data);

end

endmodule