module sync_fifo(
    input wire clk,              // Clock signal
    input wire rst,              // Asynchronous reset
    input wire write_enable,     // Write request
    input wire read_enable,      // Read request
    input wire [7:0] data_in,    // Data to be written
    output reg [7:0] data_out,   // Data to be read
    output reg fifo_full,        // Status flag (for full)
    output reg fifo_empty        // Status flag (for empty)
);

    parameter FIFO_SIZE = 16;

    reg [7:0] fifo_array [0:FIFO_SIZE-1];  // 16 x 8-bit FIFO memory

    // Pointers and counter
    reg [3:0] write_pointer = 0;           // Points to next write location
    reg [3:0] read_pointer = 0;            // Points to next read location
    reg [4:0] fifo_count = 0;              // Number of items in the FIFO buffer (0 to 16)

    
    always @(posedge clk or posedge rst) begin
        if (rst) 
            begin
                write_pointer <= 0;
                read_pointer <= 0;
                fifo_count <= 0;
                fifo_full <= 0;
                fifo_empty <= 1;
            end 
        else 
            begin
                // Write Operation
                if (write_enable && !fifo_full) begin
                    fifo_array[write_pointer] <= data_in;
                    write_pointer <= write_pointer + 1;
                    fifo_count <= fifo_count + 1;
            end

            // Read Operation
            if (read_enable && !fifo_empty) 
                begin
                    data_out <= fifo_array[read_pointer];
                    read_pointer <= read_pointer + 1;
                    fifo_count <= fifo_count - 1;
                end

            // Update status flags
            fifo_full  <= (fifo_count == FIFO_SIZE);
            fifo_empty <= (fifo_count == 0);
        end
    end

endmodule