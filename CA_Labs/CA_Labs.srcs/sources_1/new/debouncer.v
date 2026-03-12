`timescale 1ns / 1ps

module debouncer(
    input clk,          // 100MHz System Clock
    input pbin,         // Raw button input from FPGA pin
    output reg pbout    // Cleaned/Stable button output
);

    reg [19:0] timer;   // 20-bit timer for ~10ms delay
    reg [1:0] sync;     // 2-stage shift register for synchronization

    always @(posedge clk) begin
        // Shift register to sync the asynchronous button press to our clock
        sync <= {sync[0], pbin};

        // If the current button state matches our stable output, reset timer
        if (sync[1] == pbout) begin
            timer <= 0;
        end
        // If the button state is different, start counting
        else begin
            timer <= timer + 1;
            
            // If the button stays in the new state for 2^20 clock cycles (~10ms)
            if (timer == 20'hFFFFF) begin
                pbout <= sync[1]; // Update the stable output
                timer <= 0;       // Reset timer
            end
        end
    end

endmodule