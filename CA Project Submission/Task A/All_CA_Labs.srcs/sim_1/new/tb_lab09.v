`timescale 1ns / 1ps
// =========================================================
// tb_lab09.v
// Testbench for MainControl + ALUControl
// funct7 is full 7 bits [31:25] of the instruction
// only funct7[5] (instr bit [30]) distinguishes ADD/SUB
// =========================================================

module tb_lab09;

    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;   // full 7-bit funct7 [31:25]

    wire       RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUControl;

    MainControl uut_main (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    ALUControl uut_alu (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl)
    );

    task apply_and_check;
        input [63:0] instr_name;
        input [6:0]  op;
        input [2:0]  f3;
        input [6:0]  f7;   // full 7-bit funct7
        input        exp_RegWrite, exp_ALUSrc, exp_MemRead, exp_MemWrite;
        input        exp_MemtoReg, exp_Branch;
        input [1:0]  exp_ALUOp;
        input [3:0]  exp_ALUCtrl;
        begin
            opcode = op;
            funct3 = f3;
            funct7 = f7;
            #10;

            $display("-----------------------------------------------");
            $display(" Instruction : %s", instr_name);
            $display(" opcode=%b  funct3=%b  funct7=%b", opcode, funct3, funct7);
            $display(" RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b MemtoReg=%b Branch=%b",
                      RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch);
            $display(" ALUOp=%b  ALUControl=%b", ALUOp, ALUControl);

            if (RegWrite   !== exp_RegWrite)  $display("  [FAIL] RegWrite  : got %b, exp %b", RegWrite,   exp_RegWrite);
            if (ALUSrc     !== exp_ALUSrc)    $display("  [FAIL] ALUSrc    : got %b, exp %b", ALUSrc,     exp_ALUSrc);
            if (MemRead    !== exp_MemRead)   $display("  [FAIL] MemRead   : got %b, exp %b", MemRead,    exp_MemRead);
            if (MemWrite   !== exp_MemWrite)  $display("  [FAIL] MemWrite  : got %b, exp %b", MemWrite,   exp_MemWrite);
            if (Branch     !== exp_Branch)    $display("  [FAIL] Branch    : got %b, exp %b", Branch,     exp_Branch);
            if (ALUOp      !== exp_ALUOp)     $display("  [FAIL] ALUOp     : got %b, exp %b", ALUOp,      exp_ALUOp);
            if (ALUControl !== exp_ALUCtrl)   $display("  [FAIL] ALUControl: got %b, exp %b", ALUControl, exp_ALUCtrl);
            else $display("  [PASS]");
        end
    endtask

    initial begin
        $dumpfile("tb_lab09.vcd");
        $dumpvars(0, tb_lab09);

        // Initialize all inputs to avoid X state at t=0
        opcode = 7'b0;
        funct3 = 3'b0;
        funct7 = 7'b0;
        #5;

        $display("=== RISC-V Control Path Testbench ===");

        // --------------------------------------------------
        // R-type (opcode=0110011)
        // funct7=0000000 for ADD,SLL,SRL,AND,OR,XOR
        // funct7=0100000 for SUB (bit[5]=1)
        // --------------------------------------------------
        apply_and_check("ADD ",  7'b0110011, 3'b000, 7'b0000000,  1,0,0,0, 0,0, 2'b10, 4'b0010);
        apply_and_check("SUB ",  7'b0110011, 3'b000, 7'b0100000,  1,0,0,0, 0,0, 2'b10, 4'b0110);
        apply_and_check("SLL ",  7'b0110011, 3'b001, 7'b0000000,  1,0,0,0, 0,0, 2'b10, 4'b0011);
        apply_and_check("SRL ",  7'b0110011, 3'b101, 7'b0000000,  1,0,0,0, 0,0, 2'b10, 4'b0000);
        apply_and_check("AND ",  7'b0110011, 3'b111, 7'b0000000,  1,0,0,0, 0,0, 2'b10, 4'b1000);
        apply_and_check("OR  ",  7'b0110011, 3'b110, 7'b0000000,  1,0,0,0, 0,0, 2'b10, 4'b0001);
        apply_and_check("XOR ",  7'b0110011, 3'b100, 7'b0000000,  1,0,0,0, 0,0, 2'b10, 4'b0111);

        // --------------------------------------------------
        // I-type ALU (opcode=0010011)
        // funct7 is part of the immediate, use 0000000
        // --------------------------------------------------
        apply_and_check("ADDI",  7'b0010011, 3'b000, 7'b0000000,  1,1,0,0, 0,0, 2'b11, 4'b0010);

        // --------------------------------------------------
        // Load (opcode=0000011)
        // funct7 not used, always 0000000
        // --------------------------------------------------
        apply_and_check("LW  ",  7'b0000011, 3'b010, 7'b0000000,  1,1,1,0, 1,0, 2'b00, 4'b0010);
        apply_and_check("LH  ",  7'b0000011, 3'b001, 7'b0000000,  1,1,1,0, 1,0, 2'b00, 4'b0010);
        apply_and_check("LB  ",  7'b0000011, 3'b000, 7'b0000000,  1,1,1,0, 1,0, 2'b00, 4'b0010);

        // --------------------------------------------------
        // Store (opcode=0100011)
        // funct7 not used, always 0000000
        // --------------------------------------------------
        apply_and_check("SW  ",  7'b0100011, 3'b010, 7'b0000000,  0,1,0,1, 0,0, 2'b00, 4'b0010);
        apply_and_check("SH  ",  7'b0100011, 3'b001, 7'b0000000,  0,1,0,1, 0,0, 2'b00, 4'b0010);
        apply_and_check("SB  ",  7'b0100011, 3'b000, 7'b0000000,  0,1,0,1, 0,0, 2'b00, 4'b0010);

        // --------------------------------------------------
        // Branch (opcode=1100011)
        // funct7 not used, always 0000000
        // --------------------------------------------------
        apply_and_check("BEQ ",  7'b1100011, 3'b000, 7'b0000000,  0,0,0,0, 0,1, 2'b01, 4'b0110);

        $display("=== Testbench complete ===");
        $finish;
    end

endmodule
