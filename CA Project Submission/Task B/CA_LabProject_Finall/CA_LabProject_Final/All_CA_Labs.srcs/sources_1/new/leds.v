

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

//`timescale 1ns / 1ps
//// leds.v - stores full 32 bits of writeData
//// led_out is 16 bits for physical LEDs (lower 16)
//// led_out32 is full 32 bits for 32-bit display mode
//module leds (
//    input         clk,
//    input         rst,
//    input  [31:0] writeData,
//    input         writeEnable,
//    input         readEnable,
//    input  [29:0] memAddress,
//    output reg [31:0] readData,
//    output reg [15:0] leds,        // lower 16 bits for physical LEDs
//    output reg [31:0] leds32       // full 32 bits for 32-bit display mode
//);
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            leds     <= 16'b0;
//            leds32   <= 32'b0;
//            readData <= 32'b0;
//        end else if (writeEnable) begin
//            leds   <= writeData[15:0];  // physical LEDs show lower 16
//            leds32 <= writeData;        // store full 32 bits
//        end
//    end
//endmodule



//`timescale 1ns / 1ps
//// Single definition - do NOT duplicate.
//module leds (
//    input         clk,
//    input         rst,
//    input  [31:0] writeData,
//    input         writeEnable,
//    input         readEnable,
//    input  [29:0] memAddress,
//    output reg [31:0] readData,
//    output reg [15:0] leds
//);
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            leds     <= 16'b0;
//            readData <= 32'b0;
//        end else if (writeEnable) begin
//            leds <= writeData[15:0];
//        end
//    end
//endmodule


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