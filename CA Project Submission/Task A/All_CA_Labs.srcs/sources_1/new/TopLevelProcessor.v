`timescale 1ns/1ps
module TopLevelProcessor (
    input        clk,
    input        rst,
    input  [15:0] sw_in,
    output [15:0] led_out,
    output [31:0] led_out32,
    output wire [3:0]  dbgAluControl,
    output wire        dbgRegWrite,
    output wire        dbgMemRead,
    output wire        dbgMemWrite,
    output wire        dbgMemToReg,
    output wire        dbgAluSrc,
    output wire        dbgBranch,
    output wire        dbgPCSrc,
    output wire        dbgBGETaken,
    output wire        dbgJump,
    output wire        dbgJalr,
    output wire        dbgZero,
    output wire        dbgLessThan,
    output wire [31:0] dbgPC,
    output wire [31:0] dbgInstruction,
    output wire [31:0] dbgAluResult
);
    wire [31:0] PC, PCplus4, branchTarget, nextPC, pcBranchOrSeq;
    wire [31:0] instruction;
    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire        Jump, Jalr;
    wire [1:0]  ALUOp;
    wire [31:0] ReadData1, ReadData2, imm, ALUSrcB, ALUResult;
    wire [3:0]  ALUCtrl;
    wire        Zero, LessThan;
    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
    wire [31:0] writeAluOrMem, WriteBackData;
    wire        PCSrc;
    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;
    wire [31:0] ledsOut32;
    wire [31:0] ledData;          // from data memory

   wire takeBranch = (instruction[14:12] == 3'b000) ? Zero
                : (instruction[14:12] == 3'b001) ? ~Zero
                : 1'b0;

    assign PCSrc = (Branch & takeBranch) | Jump;

    assign dbgAluControl  = ALUCtrl;
    assign dbgRegWrite    = RegWrite;
    assign dbgMemRead     = MemRead;
    assign dbgMemWrite    = MemWrite;
    assign dbgMemToReg    = MemtoReg;
    assign dbgAluSrc      = ALUSrc;
    assign dbgBranch      = Branch;
    assign dbgPCSrc       = PCSrc;
    assign dbgBGETaken    = Branch & takeBranch;
    assign dbgJump        = Jump;
    assign dbgJalr        = Jalr;
    assign dbgZero        = Zero;
    assign dbgLessThan    = LessThan;
    assign dbgPC          = PC;
    assign dbgInstruction = instruction;
    assign dbgAluResult   = ALUResult;
    assign led_out32      = ledsOut32;

    ProgramCounter u_PC (
        .clk(clk), .rst(rst),
        .nextPC(nextPC), .PC(PC)
    );
    pcAdder u_pcAdder (
        .PC(PC), .PCplus4(PCplus4)
    );
    instructionMemory u_instrMem (
        .instAddress(PC), .instruction(instruction)
    );
    MainControl u_ctrl (
        .opcode(instruction[6:0]),
        .RegWrite(RegWrite), .ALUSrc(ALUSrc),
        .MemRead(MemRead),   .MemWrite(MemWrite),
        .MemtoReg(MemtoReg), .Branch(Branch),
        .ALUOp(ALUOp),       .Jump(Jump), .Jalr(Jalr)
    );
    RegisterFile u_regFile (
        .clk(clk), .rst(rst),
        .WriteEnable(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .WriteData(WriteBackData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );
    immGen u_immGen (
        .instruction(instruction), .imm(imm)
    );
    mux2 u_aluSrcMux (
        .in0(ReadData2), .in1(imm),
        .sel(ALUSrc), .out(ALUSrcB)
    );
    ALUControl u_aluCtrl (
        .ALUOp(ALUOp),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .ALUControl(ALUCtrl)
    );
    ALU u_alu (
        .A(ReadData1), .B(ALUSrcB),
        .ALUControl(ALUCtrl),
        .ALUResult(ALUResult),
        .Zero(Zero), .LessThan(LessThan)
    );
    AddressDecoder u_addrDecoder (
        .address(ALUResult[9:8]),
        .readEnable(MemRead),   .writeEnable(MemWrite),
        .dataMemWrite(dataMemWrite), .dataMemRead(dataMemRead),
        .LEDWrite(LEDWrite),    .switchReadEnable(switchReadEnable)
    );
    DataMemory u_dataMem (
        .clk(clk),
        .rst(rst),
        .memWrite(dataMemWrite),
        .memRead(dataMemRead),
        .funct3(instruction[14:12]),
        .address(ALUResult),
        .writeData(ReadData2),
        .readData(MemReadDataRaw),
        .ledData(ledData)         // NEW: LED output from memory[0]
    );
    switches u_switches (
        .clk(clk), .rst(rst),
        .btns(16'b0), .writeData(32'b0),
        .writeEnable(1'b0),
        .readEnable(switchReadEnable),
        .memAddress(ALUResult[31:2]),
        .switches(sw_in), .readData(swReadData)
    );
    leds u_leds (
        .clk(clk),
        .rst(rst),
        .ledData(ledData),        // from data memory
        .leds(led_out),
        .leds32(ledsOut32)
    );
    mux2 u_muxSwitchOrMem (
        .in0(MemReadDataRaw), .in1(swReadData),
        .sel(ALUResult[9] & ~ALUResult[8]),
        .out(MemReadData)
    );
    mux2 u_wbMux1 (
        .in0(ALUResult), .in1(MemReadData),
        .sel(MemtoReg), .out(writeAluOrMem)
    );
    mux2 u_wbMux2 (
        .in0(writeAluOrMem), .in1(PCplus4),
        .sel(Jump | Jalr), .out(WriteBackData)
    );
    branchAdder u_branchAdder (
        .PC(PC), .imm(imm), .branchTarget(branchTarget)
    );
    mux2 u_pcMux1 (
        .in0(PCplus4), .in1(branchTarget),
        .sel(PCSrc), .out(pcBranchOrSeq)
    );
    mux2 u_pcMux2 (
        .in0(pcBranchOrSeq), .in1(ALUResult),
        .sel(Jalr), .out(nextPC)
    );
endmodule
