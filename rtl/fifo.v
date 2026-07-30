// SYNCHRONOUS FIFO 

module fifo
#(
    // Configurable width and depth for scalability
    parameter FIFO_WIDTH = 32,
    parameter FIFO_DEPTH = 8
)
(
    input clk,
    input reset, // Active-low asynchronous reset
    input cs,    // Chip select
    input wr_en,
    input rd_en,
    input [FIFO_WIDTH-1 : 0] data_in,
    output reg [FIFO_WIDTH-1 : 0] data_out,
    output full,
    output empty
);

// Calculate the address width needed for the memory array
// E.g., for depth 8, clog2(8) = 3 bits
localparam FIFO_DEPTH_LOG = $clog2(FIFO_DEPTH);

// Pointers are declared 1 bit wider than the memory address.
// The extra MSB tracks wrap-around to distinguish full vs. empty states.
reg [FIFO_DEPTH_LOG : 0] read_pointer;
reg [FIFO_DEPTH_LOG : 0] write_pointer;

// The physical memory array
reg [FIFO_WIDTH-1 : 0] fifo [0 : FIFO_DEPTH - 1];

// --- Pointer Logic (Maps to standard D-Flip-Flops) ---
always @(posedge clk or negedge reset) begin
    if (!reset)
        write_pointer <= 0;
    else if (cs && wr_en && !full) begin
        write_pointer <= write_pointer + 1'b1;
    end
end

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        read_pointer <= 0;
        data_out <= 0; // Initialize to prevent 'X' states during simulation
    end
    else if (cs && rd_en && !empty) begin
        read_pointer <= read_pointer + 1'b1;
    end
end

// --- Memory Logic (Maps to dense SRAM / BRAM macros) ---
always @(posedge clk) begin
    if (cs && wr_en && !full) begin
        // Use only the lower address bits to index the memory array
        fifo[write_pointer[FIFO_DEPTH_LOG - 1 : 0]] <= data_in;
    end
end

always @(posedge clk) begin
    if (cs && rd_en && !empty) begin
        data_out <= fifo[read_pointer[FIFO_DEPTH_LOG - 1 : 0]];
    end
end

// --- Status Flags ---
assign empty = (read_pointer == write_pointer);

assign full = (read_pointer == {~write_pointer[FIFO_DEPTH_LOG] , write_pointer[FIFO_DEPTH_LOG - 1 : 0]});

endmodule