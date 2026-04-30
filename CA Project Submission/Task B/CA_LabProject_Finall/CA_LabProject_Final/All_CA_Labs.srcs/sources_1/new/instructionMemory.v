`timescale 1ns / 1ps
module instructionMemory (
    input  [31:0] instAddress,
    output reg [31:0] instruction
);
    // 64-word (256-byte) instruction memory
    reg [31:0] memory [0:63];

    initial begin
        $readmemh("programC.hex", memory);
//            $readmemh("programA.hex", memory);
    end

    // Word-addressed: divide byte address by 4
    always @(*) begin
        instruction = memory[instAddress[7:2]];
    end
endmodule

//`timescale 1ns / 1ps
//module instructionMemory#(
//    parameter OPERAND_LENGTH = 31
//)(
//    input [OPERAND_LENGTH:0] instAddress,
//    output reg [31:0] instruction
//);
 
//    reg [7:0] memory [0:255];
 
//    initial begin
//        $readmemh("instruction.mem", memory);
//    end
 
 
//    always @(*) begin
//        instruction = {memory[instAddress + 3], 
//               memory[instAddress + 2], 
//               memory[instAddress + 1], 
//               memory[instAddress]};
//    end
//endmodule