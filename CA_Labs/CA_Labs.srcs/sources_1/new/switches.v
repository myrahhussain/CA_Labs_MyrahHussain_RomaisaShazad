`timescale 1ns / 1ps

module switches(
    input clk,
    input rst,
    input [31:0] writeData,
    input writeEnable,
    input readEnable,
    input [29:0] memAddress,
    output reg [31:0] readData = 0, 
    output reg [15:0] leds // Note: Template includes this port
);
    // Logic for Lab 8:
    // When the Address Decoder sets readEnable high (address 768-1023), 
    // the value from the physical switches should be put on readData[cite: 257, 263].
endmodule