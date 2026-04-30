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
