`timescale 1ns / 1ps

module switches(
    input clk,
    input rst,
    input [31:0] writeData,
    input writeEnable,
    input readEnable,
    input [29:0] memAddress,
    output reg [31:0] readData = 0, 
    output reg [15:0] leds // This will be connected to the physical switches in XDC
);
    // Lab 8 Logic: Read physical switch status into the system
    always @(posedge clk) begin
        if (rst) begin
            readData <= 32'b0;
        end
        else if (readEnable) begin
            // Pad the 16-bit switch input with 0s to fit the 32-bit bus
            readData <= {16'b0, leds}; 
        end
        else begin
            readData <= 32'b0;
        end
    end
endmodule