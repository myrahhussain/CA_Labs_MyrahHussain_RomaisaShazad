`timescale 1ns / 1ps

module leds(
    input clk, rst,
    input [15:0] btns,
    input [31:0] writeData, 
    input writeEnable, 
    input readEnable,
    input [29:0] memAddress,
    input [15:0] switches,
    output reg [31:0] readData
);
    // This internal register holds the value for the physical LEDs
    reg [15:0] physical_leds;

    // Lab 8 Logic: Write data from the bus to the physical LEDs
    always @(posedge clk) begin
        if (rst) begin
            physical_leds <= 16'b0;
            readData <= 32'b0;
        end
        else if (writeEnable) begin
            // Update LEDs with the lower 16 bits of the data bus
            physical_leds <= writeData[15:0];
        end
    end

    // Note: To see the output on the board, you must map 'physical_leds' 
    // to the LED pins in your XDC file.
endmodule