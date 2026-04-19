`timescale 1ns / 1ps
// Single definition - do NOT duplicate.
module leds (
    input         clk,
    input         rst,
    input  [31:0] writeData,
    input         writeEnable,
    input         readEnable,
    input  [29:0] memAddress,
    output reg [31:0] readData,
    output reg [15:0] leds
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            leds     <= 16'b0;
            readData <= 32'b0;
        end else if (writeEnable) begin
            leds <= writeData[15:0];
        end
    end
endmodule
//`timescale 1ns/1ps
//module leds(
//    input clk,
//    input rst,
//    input [31:0] writeData,
//    input writeEnable,
//    input readEnable,
//    input [29:0] memAddress,
//    output reg [31:0] readData,  //=0 initially
//    output reg [15:0] leds
//);
//always @(posedge clk or posedge rst)
//begin
//    if (rst)
//        leds <= 16'b0;
//    else if (writeEnable)
//        leds <= writeData[15:0];
//end
//endmodule