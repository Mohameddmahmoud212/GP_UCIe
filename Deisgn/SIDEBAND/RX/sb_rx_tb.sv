module sb_rx_tb ;
    reg 		    i_clk;
    reg             RXCKSB;
    reg 		    i_rst_n;
    //reg             i_de_ser_done;
    reg             RXDATASB;
	reg     [3:0]   i_state;

    wire          o_tx_point_sweep_test_en;
    wire  [1:0]   o_tx_point_sweep_test;
    wire          o_rx_sb_start_pattern;
    wire          o_msg_valid;
    wire  [3:0]   o_msg_no;
    wire  [2:0]   o_msg_info;
    wire  [15:0]  o_data;
    wire          o_sb_pattern_detect_done_rx;

    ///////////////////////////////////////////////
    reg [6:0] bit_count;     // Counter to track the number of bits received
    reg [63:0] shift_reg;  

    initial begin
        i_clk = 0;
        forever begin
            #10  i_clk = ~i_clk;
        end
    end

    
    initial begin
        RXCKSB = 0;
        forever begin
            #10  RXCKSB = ~RXCKSB;
        end
    end
    SB_RX_WRAPPER sb_rx_wrapper(
     	.i_clk(i_clk),
        .RXCKSB(RXCKSB),
     	.i_rst_n(i_rst_n),
        //.i_de_ser_done(i_de_ser_done),
        .RXDATASB(RXDATASB),
        .i_state(i_state),
        .o_tx_point_sweep_test_en(o_tx_point_sweep_test_en),
        .o_tx_point_sweep_test(o_tx_point_sweep_test),
        //.o_rx_sb_start_pattern(o_rx_sb_start_pattern),
        .o_msg_valid(o_msg_valid),
        .o_msg_no(o_msg_no),
        .o_msg_info(o_msg_info),
        .o_data(o_data),
        .o_sb_pattern_detect_done_rx(o_sb_pattern_detect_done_rx)
    );
    always @(posedge RXCKSB) begin
        if(!i_rst_n)
        begin
            RXDATASB <= 0; 
            bit_count <= 0;   
        end
        else begin
            if (bit_count < 7'd64) begin
                RXDATASB  <= shift_reg[63]; 
                shift_reg <= {shift_reg[62:0], 1'b0}; 
                bit_count <= bit_count + 1;
            end else begin
                RXDATASB <= 0; 
                bit_count <= 0;   
            end
        end
    end

    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(negedge i_clk);
            end
        end
    endtask

    initial begin
    i_rst_n = 0; 
	i_state = 0; 
    bit_count = 0; 
    //pattern test
    shift_reg = 64'haaaa_aaaa_aaaa_aaaa; 
    wait_cycles(5);
    i_rst_n = 1 ; 
	i_state = 1 ; 

    wait_cycles(64);
    //sbinit req test
    //shift_reg = 64'b00_000_110_0000000000000000_0000_0001_010_0000000_1001_0101_000000000_10010;
    //mbinit resp msg
    wait_cycles(1);
    shift_reg   = 64'b00_000_110_0000000000000000_0000_0000_010_0000000_1010_1010_000000000_11011; 
    
    wait_cycles(64);
    wait_cycles(1);
    shift_reg   = 64'h1111_1111_1111_1111; 
    wait_cycles(64);
    wait_cycles(10);


    $stop;
        
    end

endmodule