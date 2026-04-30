`timescale 1ns / 1ps
// Single definition - do NOT duplicate this module anywhere else.
// ALUControl encoding:
//   0000 = SRL
//   0001 = OR
//   0010 = ADD
//   0011 = SLL
//   0110 = SUB
//   0111 = XOR
//   1000 = AND
module ALUControl (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] ALUControl
);
    wire f7b5 = funct7[5];

    always @(*) begin
        ALUControl = 4'b0010; // default: ADD

        casez ({ALUOp, funct3, f7b5})
            // ALUOp=00 : Load/Store ? ADD
            6'b00_???_?: ALUControl = 4'b0010;

            // ALUOp=01 : Branch (BEQ) ? SUB
            6'b01_???_?: ALUControl = 4'b0110;

            // ALUOp=10 : R-type
            6'b10_000_0: ALUControl = 4'b0010; // ADD
            6'b10_000_1: ALUControl = 4'b0110; // SUB
            6'b10_001_?: ALUControl = 4'b0011; // SLL
            6'b10_101_?: ALUControl = 4'b0000; // SRL
            6'b10_110_?: ALUControl = 4'b0001; // OR
            6'b10_111_?: ALUControl = 4'b1000; // AND
            6'b10_100_?: ALUControl = 4'b0111; // XOR

            // ALUOp=11 : I-type ALU (ignore funct7[5])
            6'b11_000_?: ALUControl = 4'b0010; // ADDI
            6'b11_001_?: ALUControl = 4'b0011; // SLLI
            6'b11_101_?: ALUControl = 4'b0000; // SRLI
            6'b11_110_?: ALUControl = 4'b0001; // ORI
            6'b11_111_?: ALUControl = 4'b1000; // ANDI
            6'b11_100_?: ALUControl = 4'b0111; // XORI

            default:     ALUControl = 4'b0010;
        endcase
    end
endmodule

//            default     : ALUControl = 4'b0010; // default ADD
//        endcase
//    end

//endmodule