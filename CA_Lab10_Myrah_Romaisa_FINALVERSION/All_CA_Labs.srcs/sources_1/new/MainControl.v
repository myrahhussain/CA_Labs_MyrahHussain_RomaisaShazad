`timescale 1ns / 1ps
// =========================================================
// MainControl.v
// Main Control Unit for Single-Cycle RISC-V (RV32I)
// Inputs:  opcode[6:0]
// Outputs: RegWrite, ALUSrc, MemRead, MemWrite,
//          MemtoReg, Branch, ALUOp[1:0]
// =========================================================

module MainControl (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        ALUSrc,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemtoReg,
    output reg        Branch,
    output reg [1:0]  ALUOp
);

    // RISC-V opcode definitions
    localparam R_TYPE  = 7'b0110011;  // ADD, SUB, SLL, SRL, AND, OR, XOR
    localparam I_ALU   = 7'b0010011;  // ADDI, ANDI, ORI, XORI, SLLI, SRLI
    localparam LOAD    = 7'b0000011;  // LW, LH, LB
    localparam STORE   = 7'b0100011;  // SW, SH, SB
    localparam BRANCH  = 7'b1100011;  // BEQ

    always @(*) begin
        // Safe default values (all signals de-asserted)
        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        ALUOp    = 2'b00;

        case (opcode)
            // -------------------------------------------------
            // R-type: ADD, SUB, SLL, SRL, AND, OR, XOR
            // ALU operation determined by funct3/funct7 (ALUOp=10)
            // -------------------------------------------------
            R_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;  // second ALU operand from register
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0;  // write ALU result to register
                Branch   = 1'b0;
                ALUOp    = 2'b10;
            end

            // -------------------------------------------------
            // I-type ALU: ADDI (and other immediate operations)
            // ALUOp=11 lets ALU control differentiate from loads
            // -------------------------------------------------
            I_ALU: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;  // second ALU operand from immediate
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0;  // write ALU result to register
                Branch   = 1'b0;
                ALUOp    = 2'b11;
            end

            // -------------------------------------------------
            // Load: LW, LH, LB
            // ALU computes address (add), ALUOp=00
            // -------------------------------------------------
            LOAD: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;  // immediate as offset
                MemRead  = 1'b1;
                MemWrite = 1'b0;
                MemtoReg = 1'b1;  // write memory data to register
                Branch   = 1'b0;
                ALUOp    = 2'b00;
            end

            // -------------------------------------------------
            // Store: SW, SH, SB
            // No register write; ALU computes address (add), ALUOp=00
            // -------------------------------------------------
            STORE: begin
                RegWrite = 1'b0;
                ALUSrc   = 1'b1;  // immediate as offset
                MemRead  = 1'b0;
                MemWrite = 1'b1;
                MemtoReg = 1'b0;  // don't care - no reg write
                Branch   = 1'b0;
                ALUOp    = 2'b00;
            end

            // -------------------------------------------------
            // Branch: BEQ
            // ALU subtracts rs1-rs2 to test equality, ALUOp=01
            // -------------------------------------------------
            BRANCH: begin
                RegWrite = 1'b0;
                ALUSrc   = 1'b0;  // both operands from registers
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0;  // don't care - no reg write
                Branch   = 1'b1;
                ALUOp    = 2'b01;
            end

            // -------------------------------------------------
            // Default: unknown opcode - de-assert all signals
            // -------------------------------------------------
            default: begin
                RegWrite = 1'b0;
                ALUSrc   = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0;
                Branch   = 1'b0;
                ALUOp    = 2'b00;
            end
        endcase
    end

endmodule