`timescale 1ns / 1ps
module pcAdder (
    input  [31:0] PC,
    output [31:0] PCplus4
);
    assign PCplus4 = PC + 32'd4;
endmodule

