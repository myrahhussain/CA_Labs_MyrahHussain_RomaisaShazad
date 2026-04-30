`timescale 1ns / 1ps
// =========================================================
// MainControl.v
// Supports: R-type, I-type ALU, Load, Store, Branch,
//           JAL, JALR
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

            default: begin
                // all signals stay at safe defaults
            end
        endcase
    end

endmodule


//================================TASK A============================================
//`timescale 1ns / 1ps
//// =========================================================
//// MainControl.v
//// Main Control Unit for Single-Cycle RISC-V (RV32I)
//// =========================================================
//module MainControl (
//    input  wire [6:0] opcode,
//    output reg        RegWrite,
//    output reg        ALUSrc,
//    output reg        MemRead,
//    output reg        MemWrite,
//    output reg        MemtoReg,
//    output reg        Branch,
//    output reg [1:0]  ALUOp,
//    output reg        Jump,
//    output reg        Jalr
//);

//    localparam R_TYPE  = 7'b0110011;
//    localparam I_ALU   = 7'b0010011;
//    localparam LOAD    = 7'b0000011;
//    localparam STORE   = 7'b0100011;
//    localparam BRANCH  = 7'b1100011;
//    localparam JAL     = 7'b1101111;
//    localparam JALR    = 7'b1100111;

//    always @(*) begin
//        // Safe defaults
//        RegWrite = 1'b0;
//        ALUSrc   = 1'b0;
//        MemRead  = 1'b0;
//        MemWrite = 1'b0;
//        MemtoReg = 1'b0;
//        Branch   = 1'b0;
//        ALUOp    = 2'b00;
//        Jump     = 1'b0;
//        Jalr     = 1'b0;

//        case (opcode)
//            R_TYPE: begin
//                RegWrite = 1'b1;
//                ALUSrc   = 1'b0;
//                MemtoReg = 1'b0;
//                ALUOp    = 2'b10;
//            end

//            I_ALU: begin
//                RegWrite = 1'b1;
//                ALUSrc   = 1'b1;
//                MemtoReg = 1'b0;
//                ALUOp    = 2'b11;
//            end

//            LOAD: begin
//                RegWrite = 1'b1;
//                ALUSrc   = 1'b1;
//                MemRead  = 1'b1;
//                MemtoReg = 1'b1;
//                ALUOp    = 2'b00;
//            end

//            STORE: begin
//                ALUSrc   = 1'b1;
//                MemWrite = 1'b1;
//                ALUOp    = 2'b00;
//            end

//            BRANCH: begin
//                Branch   = 1'b1;
//                ALUOp    = 2'b01;
//            end

//            JAL: begin
//                RegWrite = 1'b1;  // save PC+4 to rd
//                Jump     = 1'b1;  // take jump
//                ALUOp    = 2'b00;
//            end

//            JALR: begin
//                RegWrite = 1'b1;  // save PC+4 to rd
//                ALUSrc   = 1'b1;  // ALU computes rs1 + imm
//                Jalr     = 1'b1;  // PC = ALU result
//                ALUOp    = 2'b00;
//            end

//            default: begin
//                // all signals stay at safe defaults
//            end
//        endcase
//    end

//endmodule
