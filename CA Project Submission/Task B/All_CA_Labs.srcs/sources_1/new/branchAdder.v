

`timescale 1ns / 1ps
// immGen already encodes B-type with imm[0]=0,
// we just add directly
module branchAdder (
    input  [31:0] PC,
    input  [31:0] imm,
    output [31:0] branchTarget
);
    assign branchTarget = PC + imm;
endmodule