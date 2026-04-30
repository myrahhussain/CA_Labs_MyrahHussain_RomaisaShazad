`timescale 1ns/1ps

module tb_lab11_task1;

    reg        clk, rst, PCSrc;
    reg [31:0] instruction;
    wire [31:0] PC, PCplus4, branchTarget, nextPC, imm;

    // Instantiate all modules
    ProgramCounter  u_pc   (.clk(clk), .rst(rst), .nextPC(nextPC), .PC(PC));
    pcAdder         u_pca  (.PC(PC), .PCplus4(PCplus4));
    immGen          u_imm  (.instruction(instruction), .imm(imm));
    branchAdder     u_ba   (.PC(PC), .imm(imm), .branchTarget(branchTarget));
    mux2            u_mux  (.in0(PCplus4), .in1(branchTarget), .sel(PCSrc), .out(nextPC));

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_lab11_task1.vcd");
        $dumpvars(0, tb_lab11_task1);

        // ---- Reset ----
        rst = 1; PCSrc = 0;
        instruction = 32'b0;
        @(posedge clk); #1;
        rst = 0;

        // ---- Test 1: Sequential execution (PCSrc=0, PC should go 0,4,8,12) ----
        repeat(4) @(posedge clk);
        $display("PC after 4 cycles (expect 16): %0d", PC);

        // ---- Test 2: I-type immediate (addi x1, x0, 5)  expect imm=5 ----
        // addi opcode=0010011, rd=00001, funct3=000, rs1=00000, imm=000000000101
        instruction = 32'b000000000101_00000_000_00001_0010011;
        #1;
        $display("I-type imm (expect 5): %0d", $signed(imm));

        // ---- Test 3: I-type negative (addi x1, x0, -3)  expect imm=-3 ----
        instruction = 32'b111111111101_00000_000_00001_0010011;
        #1;
        $display("I-type imm (expect -3): %0d", $signed(imm));

        // ---- Test 4: S-type immediate (sw x1, 8(x2))  expect imm=8 ----
        // imm[11:5]=0000000, imm[4:0]=01000
        instruction = 32'b0000000_00001_00010_010_01000_0100011;
        #1;
        $display("S-type imm (expect 8): %0d", $signed(imm));

        // ---- Test 5: B-type immediate (beq x0,x0, +4)  expect imm=4 ----
        // offset=4 bytes ? encoded imm = 2 (hardware shifts left by 1)
        // imm[12]=0,imm[11]=0,imm[10:5]=000001,imm[4:1]=0000
        instruction = 32'b0_000001_00000_00000_000_0000_0_1100011;
        #1;
        $display("B-type imm (expect 4): %0d", $signed(imm));

        // ---- Test 6: Branch taken (PCSrc=1), check branchTarget ----
        rst = 1; @(posedge clk); #1; rst = 0;   // reset PC to 0
        // beq with offset +10 bytes ? imm=10
        instruction = 32'b0_000010_00000_00000_000_1010_0_1100011;
        #2;
        PCSrc = 1;
        @(posedge clk); #1;
        $display("PC after branch taken (expect 10): %0d", PC);

        $finish;
    end
endmodule