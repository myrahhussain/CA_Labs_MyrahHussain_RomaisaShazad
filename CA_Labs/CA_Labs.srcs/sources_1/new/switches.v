`timescale 1ns / 1ps

module switches(
    input clk,
    input rst,
    input [31:0] writeData,
    input writeEnable,
    input readEnable,
    input [29:0] memAddress,
    output reg [31:0] readData = 0, // Manual says: "not to be read"
    output reg [15:0] leds         // This drives the physical LEDs
);

    always @(posedge clk) begin
        if (rst) begin
            leds <= 16'b0;
        end
        else if (writeEnable) begin
            // Capture the data from the bus to turn on the lights
            leds <= writeData[15:0];
        end
    end

endmodule