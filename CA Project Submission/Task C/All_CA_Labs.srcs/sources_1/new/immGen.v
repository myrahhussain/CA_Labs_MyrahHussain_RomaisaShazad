//=======================TASK B=============================

`timescale 1ns / 1ps
// immGen - Immediate Generator
// Supports: I-type, S-type, B-type, J-type, U-type (LUI)
module immGen (
    input  [31:0] instruction,
    output reg [31:0] imm
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type: ADDI, ANDI, ORI, XORI, SLLI, SRLI, LW, LH, LB
            7'b0010011,
            7'b0000011:
                imm = {{20{instruction[31]}}, instruction[31:20]};

            // JALR (I-type)
            7'b1100111:
                imm = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: SW, SH, SB
            7'b0100011:
                imm = {{20{instruction[31]}},
                        instruction[31:25],
                        instruction[11:7]};

            // B-type: BEQ, BNE, BGE
            // imm[0] hardwired to 0
            7'b1100011:
                imm = {{19{instruction[31]}},
                        instruction[31],
                        instruction[7],
                        instruction[30:25],
                        instruction[11:8],
                        1'b0};

            // J-type: JAL
            // imm[0] hardwired to 0
            7'b1101111:
                imm = {{12{instruction[31]}},
                        instruction[19:12],
                        instruction[20],
                        instruction[30:21],
                        1'b0};

            // U-type: LUI
            // upper 20 bits, lower 12 bits zero
            7'b0110111:
                imm = {instruction[31:12], 12'b0};

            default:
                imm = 32'b0;
        endcase
    end
endmodule
