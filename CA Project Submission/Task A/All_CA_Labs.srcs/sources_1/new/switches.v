`timescale 1ns / 1ps
// Single definition - do NOT duplicate.
// Combinational read so switch value is visible immediately.
module switches (
    input         clk,
    input         rst,
    input  [15:0] btns,
    input  [31:0] writeData,
    input         writeEnable,
    input         readEnable,
    input  [29:0] memAddress,
    input  [15:0] switches,
    output reg [31:0] readData
);
    always @(*) begin
        if (readEnable)
            readData = {16'b0, switches};
        else
            readData = 32'b0;
    end
endmodule

