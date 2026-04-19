`timescale 1ns / 1ps
module instructionMemory#(
    parameter OPERAND_LENGTH = 31
)(
    input [OPERAND_LENGTH:0] instAddress,
    output reg [31:0] instruction
);
 
    reg [7:0] memory [0:255];
 
    initial begin
        $readmemh("instruction.mem", memory);
    end
 
 
    always @(*) begin
        instruction = {memory[instAddress + 3], 
               memory[instAddress + 2], 
               memory[instAddress + 1], 
               memory[instAddress]};
    end
endmodule
//`timescale 1ns / 1ps
//module instructionMemory (
//    input  [31:0] instAddress,
//    output reg [31:0] instruction
//);
//    reg [7:0] memory [0:255];

//    initial begin
//        $readmemh("instruction.mem", memory);
//    end

//    always @(*) begin
//        instruction = {memory[instAddress + 3],
//                       memory[instAddress + 2],
//                       memory[instAddress + 1],
//                       memory[instAddress]};
//    end
//endmodule
