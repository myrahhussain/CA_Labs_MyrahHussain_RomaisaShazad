`timescale 1ns / 1ps

module leds (
    input clk, rst,
    input [15:0] btns,
    input [31:0] writeData, 
    input writeEnable, 
    input readEnable,
    input [29:0] memAddress,
    input [15:0] switches,
    output reg [31:0] readData
);
    // Logic for Lab 8:
    // When the Address Decoder sets writeEnable high (address 512-767),
    // the writeData from the CPU is used to update the LEDs[cite: 257, 262].
endmodule