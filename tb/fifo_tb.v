`timescale  1ns/1ns
module tb_fifo;

    // FIFO configuration parameters matching the DUT
    parameter FIFO_DEPTH = 8 , FIFO_WIDTH = 32;
    
    reg clk = 0;
    reg reset;
    reg cs; // chip select
    reg wr_en;
    reg rd_en;
    reg [FIFO_WIDTH-1 : 0] data_in;
    
    wire [FIFO_WIDTH-1 : 0] data_out;
    wire full;
    wire empty;

    integer i;

    // Device Under Test (DUT) instantiation
    fifo #(.FIFO_DEPTH(FIFO_DEPTH) , .FIFO_WIDTH (FIFO_WIDTH)) dut (
        .clk (clk),
        .reset (reset),
        .cs (cs),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .data_in (data_in),
        .data_out (data_out),
        .full (full),
        .empty (empty)
    );

    // Clock generation (10ns time period)
    always #5 clk = ~clk;

    // Task to perform a single synchronous write operation
    task write_data(input [FIFO_WIDTH - 1 : 0] d_in);
     begin
        @(posedge clk); 
        cs <= 1; wr_en <= 1;
        data_in <= d_in;
        $display($time, " write_data data_in = %0d", d_in );
        
        @(posedge clk);
        cs <= 0; wr_en <= 0;
     end
    endtask

    // Task to perform a single synchronous read operation
    task read_data();
     begin
        @(posedge clk); 
        cs <= 1; rd_en <= 1;
        
        @(posedge clk);
        cs <= 0; rd_en <= 0;
        
        #1; // Slight delay to safely capture the updated data_out for the display log
        $display($time, " read_data data_out = %0d", data_out );
     end
    endtask

    // Main stimulus block
    initial begin
        // Initialize signals and apply active-low reset
        #1;
        reset = 0; rd_en = 0; wr_en = 0;

        @(posedge clk) 
        reset <= 1; // Release reset
        
        // Test 1: Verify basic sequential writes followed by sequential reads
        $display($time, "\n SCENARIO 1: Basic Write and Read" );
        write_data(1);
        write_data(10);
        write_data(100);
        read_data();
        read_data();
        read_data();

        // Test 2: Verify simultaneous write/read handling
        $display($time, "\n SCENARIO 2: Interleaved Write and Read" );
        for (i = 0; i < FIFO_DEPTH ; i++ ) begin
            write_data(2*i);
            read_data();
        end

        // Test 3: Verify the full and empty flag logic boundaries
        $display($time, "\n SCENARIO 3: Fill to Depth, then Empty" );
        for (i = 0; i < FIFO_DEPTH ; i++ ) begin
            write_data(2*i);
        end

        for (i = 0; i < FIFO_DEPTH ; i++ ) begin
            read_data();
        end

        #40 $finish;
    end

    initial begin
        $dumpfile("fif.vcd");
        $dumpvars(0,tb_fifo);
    end

endmodule