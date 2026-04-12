`timescale 1ns / 1ps
// =========================================================
// ALUControl.v
// ALU Control Unit for Single-Cycle RISC-V (RV32I)
//
// Inputs:  ALUOp[1:0]  - from Main Control
//          funct3[2:0] - instruction bits [14:12]
//          funct7[6:0] - instruction bits [31:25]
//                        only funct7[5] (instr bit [30])
//                        is used to distinguish ADD/SUB
// Output:  ALUControl[3:0]
//
// ALUControl encoding:
//   0000 = SRL
//   0001 = OR
//   0010 = ADD
//   0011 = SLL
//   0110 = SUB
//   0111 = XOR
//   1000 = AND
// =========================================================

module ALUControl (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,   // full funct7, bits [31:25] of instruction
    output reg  [3:0] ALUControl
);

    // funct7[5] corresponds to instruction bit [30]
    // it is the only bit that distinguishes ADD (0) from SUB (1)
    wire f7b5 = funct7[5];

    always @(*) begin
        // Safe default
        ALUControl = 4'b0010; // ADD

        casez ({ALUOp, funct3, f7b5})
            // -------------------------------------------------
            // ALUOp = 00 : Load / Store ? always ADD
            // -------------------------------------------------
            6'b00_???_? : ALUControl = 4'b0010; // ADD

            // -------------------------------------------------
            // ALUOp = 01 : Branch (BEQ) ? always SUB
            // -------------------------------------------------
            6'b01_???_? : ALUControl = 4'b0110; // SUB

            // -------------------------------------------------
            // ALUOp = 10 : R-type
            // funct7[5]=0 ? ADD, funct7[5]=1 ? SUB
            // -------------------------------------------------
            6'b10_000_0 : ALUControl = 4'b0010; // ADD
            6'b10_000_1 : ALUControl = 4'b0110; // SUB
            6'b10_001_? : ALUControl = 4'b0011; // SLL
            6'b10_101_? : ALUControl = 4'b0000; // SRL
            6'b10_110_? : ALUControl = 4'b0001; // OR
            6'b10_111_? : ALUControl = 4'b1000; // AND
            6'b10_100_? : ALUControl = 4'b0111; // XOR

            // -------------------------------------------------
            // ALUOp = 11 : I-type ALU
            // funct7 is part of the immediate - ignore funct7[5]
            // -------------------------------------------------
            6'b11_000_? : ALUControl = 4'b0010; // ADDI
            6'b11_001_? : ALUControl = 4'b0011; // SLLI
            6'b11_101_? : ALUControl = 4'b0000; // SRLI
            6'b11_110_? : ALUControl = 4'b0001; // ORI
            6'b11_111_? : ALUControl = 4'b1000; // ANDI
            6'b11_100_? : ALUControl = 4'b0111; // XORI

            default     : ALUControl = 4'b0010; // ADD
        endcase
    end

endmodule

//`timescale 1ns / 1ps
//// =========================================================
//// ALUControl.v
//// ALU Control Unit for Single-Cycle RISC-V (RV32I)
////
//// Inputs:  ALUOp[1:0]  - from Main Control
////          funct3[2:0] - instruction bits [14:12]
////          funct7      - instruction bit  [30] (funct7[5])
//// Output:  ALUControl[3:0]
////
//// ALUControl encoding:
////   0000 = SRL  (logical shift right)
////   0001 = OR
////   0010 = ADD
////   0011 = SLL  (shift left logical)
////   0110 = SUB
////   0111 = XOR
////   1000 = AND
//// =========================================================

//module ALUControl (
//    input  wire [1:0] ALUOp,
//    input  wire [2:0] funct3,
//    input  wire       funct7,   // pass in bit [30] of the instruction
//    output reg  [3:0] ALUControl
//);

//    always @(*) begin
//        // Safe default
//        ALUControl = 4'b0010; // ADD

//        casez ({ALUOp, funct3, funct7})
//            // -------------------------------------------------
//            // ALUOp = 00 : Load / Store  ? always ADD
//            // -------------------------------------------------
//            6'b00_???_? : ALUControl = 4'b0010; // ADD

//            // -------------------------------------------------
//            // ALUOp = 01 : Branch (BEQ)  ? always SUB
//            // -------------------------------------------------
//            6'b01_???_? : ALUControl = 4'b0110; // SUB

//            // -------------------------------------------------
//            // ALUOp = 10 : R-type  (funct7 bit distinguishes ADD/SUB)
//            // -------------------------------------------------
//            6'b10_000_0 : ALUControl = 4'b0010; // ADD  (funct7=0)
//            6'b10_000_1 : ALUControl = 4'b0110; // SUB  (funct7=1)
//            6'b10_001_? : ALUControl = 4'b0011; // SLL
//            6'b10_101_? : ALUControl = 4'b0000; // SRL
//            6'b10_110_? : ALUControl = 4'b0001; // OR
//            6'b10_111_? : ALUControl = 4'b1000; // AND
//            6'b10_100_? : ALUControl = 4'b0111; // XOR

//            // -------------------------------------------------
//            // ALUOp = 11 : I-type ALU  (ADDI, ANDI, ORI, etc.)
//            //              funct7 is part of the immediate - ignore it
//            // -------------------------------------------------
//            6'b11_000_? : ALUControl = 4'b0010; // ADDI
//            6'b11_001_? : ALUControl = 4'b0011; // SLLI
//            6'b11_101_? : ALUControl = 4'b0000; // SRLI
//            6'b11_110_? : ALUControl = 4'b0001; // ORI
//            6'b11_111_? : ALUControl = 4'b1000; // ANDI
//            6'b11_100_? : ALUControl = 4'b0111; // XORI

//            default     : ALUControl = 4'b0010; // default ADD
//        endcase
//    end

//endmodule