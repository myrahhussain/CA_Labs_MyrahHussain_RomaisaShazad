`timescale 1ns / 1ps
// =========================================================
// MainControl.v
// Supports: R-type, I-type ALU, Load, Store, Branch,
//           JAL, JALR, LUI
// =========================================================
module MainControl (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        ALUSrc,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemtoReg,
    output reg        Branch,
    output reg [1:0]  ALUOp,
    output reg        Jump,
    output reg        Jalr
);

    localparam R_TYPE  = 7'b0110011;
    localparam I_ALU   = 7'b0010011;
    localparam LOAD    = 7'b0000011;
    localparam STORE   = 7'b0100011;
    localparam BRANCH  = 7'b1100011;
    localparam JAL     = 7'b1101111;
    localparam JALR    = 7'b1100111;
    localparam LUI     = 7'b0110111;  // NEW: Load Upper Immediate

    always @(*) begin
        // Safe defaults
        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        ALUOp    = 2'b00;
        Jump     = 1'b0;
        Jalr     = 1'b0;

        case (opcode)
            R_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                ALUOp    = 2'b10;
            end

            I_ALU: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b11;
            end

            LOAD: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUOp    = 2'b00;
            end

            STORE: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = 2'b00;
            end

            BRANCH: begin
                Branch   = 1'b1;
                ALUOp    = 2'b01;
            end

            JAL: begin
                RegWrite = 1'b1;
                Jump     = 1'b1;
                ALUOp    = 2'b00;
            end

            JALR: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                Jalr     = 1'b1;
                ALUOp    = 2'b00;
            end

            LUI: begin
                // rd = imm (upper 20 bits)
                // ALUSrc=1 passes imm to ALU
                // ALUOp=00 does ADD, rs1=x0 so result = 0 + imm = imm
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end

            default: begin
                // all signals stay at safe defaults
            end
        endcase
    end

endmodule
