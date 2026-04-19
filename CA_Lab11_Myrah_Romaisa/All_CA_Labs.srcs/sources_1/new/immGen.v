`timescale 1ns / 1ps
module immGen (
    input  [31:0] instruction,
    output reg [31:0] imm
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type: addi, andi, ori, xori, slli, srli, lw, lb, lh, jalr
            7'b0010011,  // arithmetic immediate
            7'b0000011,  // load
            7'b1100111:  // jalr
                imm = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: sw, sb, sh
            7'b0100011:
                imm = {{20{instruction[31]}},
                        instruction[31:25],
                        instruction[11:7]};

            // B-type: beq, bne, blt, bge
            // imm[12]   = inst[31]
            // imm[11]   = inst[7]
            // imm[10:5] = inst[30:25]
            // imm[4:1]  = inst[11:8]
            // imm[0]    = 0  (hardwired - this means NO extra shift needed in branchAdder)
            7'b1100011:
                imm = {{19{instruction[31]}},
                        instruction[31],
                        instruction[7],
                        instruction[30:25],
                        instruction[11:8],
                        1'b0};

            default:
                imm = 32'b0;
        endcase
    end
endmodule
