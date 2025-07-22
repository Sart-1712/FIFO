module async_fifo
(
    input wire write_clk,                  // Write clock 
    input wire read_clk,                   // Read clock 
    input wire reset,                      // Asynchronous reset

    input wire write_enable,               // Signal to write data
    input wire [DATA_WIDTH-1:0] data_in,   // Data input
    output wire fifo_full,                 // FIFO full flag

    input wire read_enable,                // Signal to read data
    output reg [DATA_WIDTH-1:0] data_out,  // Data output
    output wire fifo_empty                 // FIFO empty flag
);

    parameter DATA_WIDTH = 8,              // Width of data (8 bits in this case)
    parameter ADDRESS_WIDTH = 4            // Log2 of FIFO depth (2^4 = 16 entries in this case)

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDRESS_WIDTH)-1]; //FIFO Internal Memory - 16 x 8-bit 

    // Binary Pointers
    reg [ADDRESS_WIDTH:0] write_pointer_bin = 0;
    reg [ADDRESS_WIDTH:0] read_pointer_bin = 0;

    // Gray Code Pointers
    reg [ADDRESS_WIDTH:0] write_pointer_gray = 0;
    reg [ADDRESS_WIDTH:0] read_pointer_gray = 0;

    // Synchronized pointers for CDC
    reg [ADDRESS_WIDTH:0] read_pointer_gray_sync1 = 0, read_pointer_gray_sync2 = 0;
    reg [ADDRESS_WIDTH:0] write_pointer_gray_sync1 = 0, write_pointer_gray_sync2 = 0;

    
    always @(posedge write_clk or posedge reset) begin
        if (reset) begin
            write_pointer_bin <= 0;
            write_pointer_gray <= 0;
        end else if (write_enable && !fifo_full) begin
            memory[write_pointer_bin[ADDRESS_WIDTH-1:0]] <= data_in;
            write_pointer_bin <= write_pointer_bin + 1;
            write_pointer_gray <= (write_pointer_bin >> 1) ^ write_pointer_bin;  // Binary to Gray
        end
    end

    
    always @(posedge read_clk or posedge reset) begin
        if (reset) begin
            read_pointer_bin <= 0;
            read_pointer_gray <= 0;
            data_out <= 0;
        end else if (read_enable && !fifo_empty) begin
            data_out <= memory[read_pointer_bin[ADDRESS_WIDTH-1:0]];
            read_pointer_bin <= read_pointer_bin + 1;
            read_pointer_gray <= (read_pointer_bin >> 1) ^ read_pointer_bin;  // Binary to Gray
        end
    end

    // Synchronizing read pointer to write clock domain
    always @(posedge write_clk or posedge reset) begin
        if (reset) begin
            read_pointer_gray_sync1 <= 0;
            read_pointer_gray_sync2 <= 0;
        end else begin
            read_pointer_gray_sync1 <= read_pointer_gray;
            read_pointer_gray_sync2 <= read_pointer_gray_sync1;
        end
    end

    // Synchronizing write pointer to read clock domain
    always @(posedge read_clk or posedge reset) begin
        if (reset) begin
            write_pointer_gray_sync1 <= 0;
            write_pointer_gray_sync2 <= 0;
        end else begin
            write_pointer_gray_sync1 <= write_pointer_gray;
            write_pointer_gray_sync2 <= write_pointer_gray_sync1;
        end
    end

    
    assign fifo_full = (write_pointer_gray == 
                        {~read_pointer_gray_sync2[ADDRESS_WIDTH:ADDRESS_WIDTH-1], read_pointer_gray_sync2[ADDRESS_WIDTH-2:0]});

    assign fifo_empty = (read_pointer_gray == write_pointer_gray_sync2);

endmodule