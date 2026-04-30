

`timescale 1ns / 1ps
module leds (
    input         clk,
    input         rst,
    input  [31:0] ledData,        // from data memory address 0
    output wire [15:0] leds,      // lower 16 bits for physical LEDs
    output wire [31:0] leds32     // full 32 bits
);
    assign leds   = ledData[15:0];
    assign leds32 = ledData;
endmodule
