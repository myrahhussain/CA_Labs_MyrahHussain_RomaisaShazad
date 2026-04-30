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
                    : (instruction[14:12] == 3'b101) ? ~LessThan
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

//`timescale 1ns/1ps
//module TopLevelProcessor (
//    input        clk,
//    input        rst,
//    input  [15:0] sw_in,
//    output [15:0] led_out,
//    output [31:0] led_out32,       // NEW: full 32-bit LED output
//    output wire [3:0]  dbgAluControl,
//    output wire        dbgRegWrite,
//    output wire        dbgMemRead,
//    output wire        dbgMemWrite,
//    output wire        dbgMemToReg,
//    output wire        dbgAluSrc,
//    output wire        dbgBranch,
//    output wire        dbgPCSrc,
//    output wire        dbgBGETaken,
//    output wire        dbgJump,
//    output wire        dbgJalr,
//    output wire        dbgZero,
//    output wire        dbgLessThan,
//    output wire [31:0] dbgPC,
//    output wire [31:0] dbgInstruction,
//    output wire [31:0] dbgAluResult
//);
//    wire [31:0] PC, PCplus4, branchTarget, nextPC, pcBranchOrSeq;
//    wire [31:0] instruction;
//    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
//    wire        Jump, Jalr;
//    wire [1:0]  ALUOp;
//    wire [31:0] ReadData1, ReadData2, imm, ALUSrcB, ALUResult;
//    wire [3:0]  ALUCtrl;
//    wire        Zero, LessThan;
//    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
//    wire [31:0] writeAluOrMem, WriteBackData;
//    wire        PCSrc;
//    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;
//    wire [31:0] ledsOut32;         // full 32-bit from leds module

//    wire takeBranch = (instruction[14:12] == 3'b000) ? Zero
//                    : (instruction[14:12] == 3'b001) ? ~Zero
//                    : (instruction[14:12] == 3'b101) ? ~LessThan
//                    : 1'b0;

//    assign PCSrc = (Branch & takeBranch) | Jump;

//    // Debug assignments
//    assign dbgAluControl  = ALUCtrl;
//    assign dbgRegWrite    = RegWrite;
//    assign dbgMemRead     = MemRead;
//    assign dbgMemWrite    = MemWrite;
//    assign dbgMemToReg    = MemtoReg;
//    assign dbgAluSrc      = ALUSrc;
//    assign dbgBranch      = Branch;
//    assign dbgPCSrc       = PCSrc;
//    assign dbgBGETaken    = Branch & takeBranch;
//    assign dbgJump        = Jump;
//    assign dbgJalr        = Jalr;
//    assign dbgZero        = Zero;
//    assign dbgLessThan    = LessThan;
//    assign dbgPC          = PC;
//    assign dbgInstruction = instruction;
//    assign dbgAluResult   = ALUResult;
//    assign led_out32      = ledsOut32;

//    ProgramCounter u_PC (
//        .clk(clk), .rst(rst),
//        .nextPC(nextPC), .PC(PC)
//    );
//    pcAdder u_pcAdder (
//        .PC(PC), .PCplus4(PCplus4)
//    );
//    instructionMemory u_instrMem (
//        .instAddress(PC), .instruction(instruction)
//    );
//    MainControl u_ctrl (
//        .opcode(instruction[6:0]),
//        .RegWrite(RegWrite), .ALUSrc(ALUSrc),
//        .MemRead(MemRead),   .MemWrite(MemWrite),
//        .MemtoReg(MemtoReg), .Branch(Branch),
//        .ALUOp(ALUOp),       .Jump(Jump), .Jalr(Jalr)
//    );
//    RegisterFile u_regFile (
//        .clk(clk), .rst(rst),
//        .WriteEnable(RegWrite),
//        .rs1(instruction[19:15]),
//        .rs2(instruction[24:20]),
//        .rd(instruction[11:7]),
//        .WriteData(WriteBackData),
//        .ReadData1(ReadData1), .ReadData2(ReadData2)
//    );
//    immGen u_immGen (
//        .instruction(instruction), .imm(imm)
//    );
//    mux2 u_aluSrcMux (
//        .in0(ReadData2), .in1(imm),
//        .sel(ALUSrc), .out(ALUSrcB)
//    );
//    ALUControl u_aluCtrl (
//        .ALUOp(ALUOp),
//        .funct3(instruction[14:12]),
//        .funct7(instruction[31:25]),
//        .ALUControl(ALUCtrl)
//    );
//    ALU u_alu (
//        .A(ReadData1), .B(ALUSrcB),
//        .ALUControl(ALUCtrl),
//        .ALUResult(ALUResult),
//        .Zero(Zero), .LessThan(LessThan)
//    );
//    AddressDecoder u_addrDecoder (
//        .address(ALUResult[9:8]),
//        .readEnable(MemRead),   .writeEnable(MemWrite),
//        .dataMemWrite(dataMemWrite), .dataMemRead(dataMemRead),
//        .LEDWrite(LEDWrite),    .switchReadEnable(switchReadEnable)
//    );
//    DataMemory u_dataMem (
//        .clk(clk),
//        .rst(rst),
//        .memWrite(dataMemWrite),
//        .memRead(dataMemRead),
//        .funct3(instruction[14:12]),
//        .address(ALUResult),
//        .writeData(ReadData2),
//        .readData(MemReadDataRaw)
//    );
//    switches u_switches (
//        .clk(clk), .rst(rst),
//        .btns(16'b0), .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(switchReadEnable),
//        .memAddress(ALUResult[31:2]),
//        .switches(sw_in), .readData(swReadData)
//    );
//    leds u_leds (
//        .clk(clk), .rst(rst),
//        .writeData(ReadData2),
//        .writeEnable(LEDWrite),
//        .readEnable(1'b0),
//        .memAddress(ALUResult[31:2]),
//        .readData(),
//        .leds(led_out),
//        .leds32(ledsOut32)     // full 32-bit output
//    );
//    mux2 u_muxSwitchOrMem (
//        .in0(MemReadDataRaw), .in1(swReadData),
//        .sel(ALUResult[9] & ~ALUResult[8]),
//        .out(MemReadData)
//    );
//    mux2 u_wbMux1 (
//        .in0(ALUResult), .in1(MemReadData),
//        .sel(MemtoReg), .out(writeAluOrMem)
//    );
//    mux2 u_wbMux2 (
//        .in0(writeAluOrMem), .in1(PCplus4),
//        .sel(Jump | Jalr), .out(WriteBackData)
//    );
//    branchAdder u_branchAdder (
//        .PC(PC), .imm(imm), .branchTarget(branchTarget)
//    );
//    mux2 u_pcMux1 (
//        .in0(PCplus4), .in1(branchTarget),
//        .sel(PCSrc), .out(pcBranchOrSeq)
//    );
//    mux2 u_pcMux2 (
//        .in0(pcBranchOrSeq), .in1(ALUResult),
//        .sel(Jalr), .out(nextPC)
//    );
//endmodule


//`timescale 1ns/1ps
//module TopLevelProcessor (
//    input        clk,
//    input        rst,
//    input  [15:0] sw_in,
//    output [15:0] led_out,
//    output wire [3:0]  dbgAluControl,
//    output wire        dbgRegWrite,
//    output wire        dbgMemRead,
//    output wire        dbgMemWrite,
//    output wire        dbgMemToReg,
//    output wire        dbgAluSrc,
//    output wire        dbgBranch,
//    output wire        dbgPCSrc,      // NEW: actual branch taken signal
//    output wire        dbgJump,
//    output wire        dbgJalr,
//    output wire        dbgZero,
//    output wire        dbgLessThan,
//    output wire [31:0] dbgPC,
//    output wire [31:0] dbgInstruction,
//    output wire [31:0] dbgAluResult
//);
//    wire [31:0] PC, PCplus4, branchTarget, nextPC, pcBranchOrSeq;
//    wire [31:0] instruction;
//    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
//    wire        Jump, Jalr;
//    wire [1:0]  ALUOp;
//    wire [31:0] ReadData1, ReadData2, imm, ALUSrcB, ALUResult;
//    wire [3:0]  ALUCtrl;
//    wire        Zero, LessThan;
//    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
//    wire [31:0] writeAluOrMem, WriteBackData;
//    wire        PCSrc;
//    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;

//    wire takeBranch = (instruction[14:12] == 3'b000) ? Zero
//                    : (instruction[14:12] == 3'b001) ? ~Zero
//                    : (instruction[14:12] == 3'b101) ? ~LessThan
//                    : 1'b0;

//    assign PCSrc = (Branch & takeBranch) | Jump;

//    // Debug assignments
//    assign dbgAluControl  = ALUCtrl;
//    assign dbgRegWrite    = RegWrite;
//    assign dbgMemRead     = MemRead;
//    assign dbgMemWrite    = MemWrite;
//    assign dbgMemToReg    = MemtoReg;
//    assign dbgAluSrc      = ALUSrc;
//    assign dbgBranch      = Branch;
//    assign dbgPCSrc       = PCSrc;       // NEW: high only when branch actually taken
//    assign dbgJump        = Jump;
//    assign dbgJalr        = Jalr;
//    assign dbgZero        = Zero;
//    assign dbgLessThan    = LessThan;
//    assign dbgPC          = PC;
//    assign dbgInstruction = instruction;
//    assign dbgAluResult   = ALUResult;

//    ProgramCounter u_PC (
//        .clk(clk), .rst(rst),
//        .nextPC(nextPC), .PC(PC)
//    );
//    pcAdder u_pcAdder (
//        .PC(PC), .PCplus4(PCplus4)
//    );
//    instructionMemory u_instrMem (
//        .instAddress(PC), .instruction(instruction)
//    );
//    MainControl u_ctrl (
//        .opcode(instruction[6:0]),
//        .RegWrite(RegWrite), .ALUSrc(ALUSrc),
//        .MemRead(MemRead),   .MemWrite(MemWrite),
//        .MemtoReg(MemtoReg), .Branch(Branch),
//        .ALUOp(ALUOp),       .Jump(Jump), .Jalr(Jalr)
//    );
//    RegisterFile u_regFile (
//        .clk(clk), .rst(rst),
//        .WriteEnable(RegWrite),
//        .rs1(instruction[19:15]),
//        .rs2(instruction[24:20]),
//        .rd(instruction[11:7]),
//        .WriteData(WriteBackData),
//        .ReadData1(ReadData1), .ReadData2(ReadData2)
//    );
//    immGen u_immGen (
//        .instruction(instruction), .imm(imm)
//    );
//    mux2 u_aluSrcMux (
//        .in0(ReadData2), .in1(imm),
//        .sel(ALUSrc), .out(ALUSrcB)
//    );
//    ALUControl u_aluCtrl (
//        .ALUOp(ALUOp),
//        .funct3(instruction[14:12]),
//        .funct7(instruction[31:25]),
//        .ALUControl(ALUCtrl)
//    );
//    ALU u_alu (
//        .A(ReadData1), .B(ALUSrcB),
//        .ALUControl(ALUCtrl),
//        .ALUResult(ALUResult),
//        .Zero(Zero), .LessThan(LessThan)
//    );
//    AddressDecoder u_addrDecoder (
//        .address(ALUResult[9:8]),
//        .readEnable(MemRead),   .writeEnable(MemWrite),
//        .dataMemWrite(dataMemWrite), .dataMemRead(dataMemRead),
//        .LEDWrite(LEDWrite),    .switchReadEnable(switchReadEnable)
//    );
//    DataMemory u_dataMem (
//        .clk(clk),
//        .rst(rst),
//        .memWrite(dataMemWrite),
//        .memRead(dataMemRead),
//        .funct3(instruction[14:12]),
//        .address(ALUResult),
//        .writeData(ReadData2),
//        .readData(MemReadDataRaw)
//    );
//    switches u_switches (
//        .clk(clk), .rst(rst),
//        .btns(16'b0), .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(switchReadEnable),
//        .memAddress(ALUResult[31:2]),
//        .switches(sw_in), .readData(swReadData)
//    );
//    leds u_leds (
//        .clk(clk), .rst(rst),
//        .writeData(ReadData2),
//        .writeEnable(LEDWrite),
//        .readEnable(1'b0),
//        .memAddress(ALUResult[31:2]),
//        .readData(), .leds(led_out)
//    );
//    mux2 u_muxSwitchOrMem (
//        .in0(MemReadDataRaw), .in1(swReadData),
//        .sel(ALUResult[9] & ~ALUResult[8]),
//        .out(MemReadData)
//    );
//    mux2 u_wbMux1 (
//        .in0(ALUResult), .in1(MemReadData),
//        .sel(MemtoReg), .out(writeAluOrMem)
//    );
//    mux2 u_wbMux2 (
//        .in0(writeAluOrMem), .in1(PCplus4),
//        .sel(Jump | Jalr), .out(WriteBackData)
//    );
//    branchAdder u_branchAdder (
//        .PC(PC), .imm(imm), .branchTarget(branchTarget)
//    );
//    mux2 u_pcMux1 (
//        .in0(PCplus4), .in1(branchTarget),
//        .sel(PCSrc), .out(pcBranchOrSeq)
//    );
//    mux2 u_pcMux2 (
//        .in0(pcBranchOrSeq), .in1(ALUResult),
//        .sel(Jalr), .out(nextPC)
//    );
//endmodule

//`timescale 1ns/1ps
//module TopLevelProcessor (
//    input        clk,
//    input        rst,
//    input  [15:0] sw_in,
//    output [15:0] led_out,
//    output wire [3:0]  dbgAluControl,
//    output wire        dbgRegWrite,
//    output wire        dbgMemRead,
//    output wire        dbgMemWrite,
//    output wire        dbgMemToReg,
//    output wire        dbgAluSrc,
//    output wire        dbgBranch,
//    output wire        dbgJump,
//    output wire        dbgJalr,
//    output wire        dbgZero,
//    output wire        dbgLessThan,
//    output wire [31:0] dbgPC,
//    output wire [31:0] dbgInstruction,
//    output wire [31:0] dbgAluResult       // NEW: ALU result for display
//);
//    wire [31:0] PC, PCplus4, branchTarget, nextPC, pcBranchOrSeq;
//    wire [31:0] instruction;
//    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
//    wire        Jump, Jalr;
//    wire [1:0]  ALUOp;
//    wire [31:0] ReadData1, ReadData2, imm, ALUSrcB, ALUResult;
//    wire [3:0]  ALUCtrl;
//    wire        Zero, LessThan;
//    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
//    wire [31:0] writeAluOrMem, WriteBackData;
//    wire        PCSrc;
//    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;

//    wire takeBranch = (instruction[14:12] == 3'b000) ? Zero
//                    : (instruction[14:12] == 3'b001) ? ~Zero
//                    : (instruction[14:12] == 3'b101) ? ~LessThan
//                    : 1'b0;

//    assign PCSrc = (Branch & takeBranch) | Jump;

//    // Debug signal assignments
//    assign dbgAluControl  = ALUCtrl;
//    assign dbgRegWrite    = RegWrite;
//    assign dbgMemRead     = MemRead;
//    assign dbgMemWrite    = MemWrite;
//    assign dbgMemToReg    = MemtoReg;
//    assign dbgAluSrc      = ALUSrc;
//    assign dbgBranch      = Branch;
//    assign dbgJump        = Jump;
//    assign dbgJalr        = Jalr;
//    assign dbgZero        = Zero;
//    assign dbgLessThan    = LessThan;
//    assign dbgPC          = PC;
//    assign dbgInstruction = instruction;
//    assign dbgAluResult   = ALUResult;   // NEW

//    ProgramCounter u_PC (
//        .clk(clk), .rst(rst),
//        .nextPC(nextPC), .PC(PC)
//    );
//    pcAdder u_pcAdder (
//        .PC(PC), .PCplus4(PCplus4)
//    );
//    instructionMemory u_instrMem (
//        .instAddress(PC), .instruction(instruction)
//    );
//    MainControl u_ctrl (
//        .opcode(instruction[6:0]),
//        .RegWrite(RegWrite), .ALUSrc(ALUSrc),
//        .MemRead(MemRead),   .MemWrite(MemWrite),
//        .MemtoReg(MemtoReg), .Branch(Branch),
//        .ALUOp(ALUOp),       .Jump(Jump), .Jalr(Jalr)
//    );
//    RegisterFile u_regFile (
//        .clk(clk), .rst(rst),
//        .WriteEnable(RegWrite),
//        .rs1(instruction[19:15]),
//        .rs2(instruction[24:20]),
//        .rd(instruction[11:7]),
//        .WriteData(WriteBackData),
//        .ReadData1(ReadData1), .ReadData2(ReadData2)
//    );
//    immGen u_immGen (
//        .instruction(instruction), .imm(imm)
//    );
//    mux2 u_aluSrcMux (
//        .in0(ReadData2), .in1(imm),
//        .sel(ALUSrc), .out(ALUSrcB)
//    );
//    ALUControl u_aluCtrl (
//        .ALUOp(ALUOp),
//        .funct3(instruction[14:12]),
//        .funct7(instruction[31:25]),
//        .ALUControl(ALUCtrl)
//    );
//    ALU u_alu (
//        .A(ReadData1), .B(ALUSrcB),
//        .ALUControl(ALUCtrl),
//        .ALUResult(ALUResult),
//        .Zero(Zero), .LessThan(LessThan)
//    );
//    AddressDecoder u_addrDecoder (
//        .address(ALUResult[9:8]),
//        .readEnable(MemRead),   .writeEnable(MemWrite),
//        .dataMemWrite(dataMemWrite), .dataMemRead(dataMemRead),
//        .LEDWrite(LEDWrite),    .switchReadEnable(switchReadEnable)
//    );
//    DataMemory u_dataMem (
//        .clk(clk),
//        .rst(rst),
//        .memWrite(dataMemWrite),
//        .memRead(dataMemRead),
//        .funct3(instruction[14:12]),
//        .address(ALUResult),
//        .writeData(ReadData2),
//        .readData(MemReadDataRaw)
//    );
//    switches u_switches (
//        .clk(clk), .rst(rst),
//        .btns(16'b0), .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(switchReadEnable),
//        .memAddress(ALUResult[31:2]),
//        .switches(sw_in), .readData(swReadData)
//    );
//    leds u_leds (
//        .clk(clk), .rst(rst),
//        .writeData(ReadData2),
//        .writeEnable(LEDWrite),
//        .readEnable(1'b0),
//        .memAddress(ALUResult[31:2]),
//        .readData(), .leds(led_out)
//    );
//    mux2 u_muxSwitchOrMem (
//        .in0(MemReadDataRaw), .in1(swReadData),
//        .sel(ALUResult[9] & ~ALUResult[8]),
//        .out(MemReadData)
//    );
//    mux2 u_wbMux1 (
//        .in0(ALUResult), .in1(MemReadData),
//        .sel(MemtoReg), .out(writeAluOrMem)
//    );
//    mux2 u_wbMux2 (
//        .in0(writeAluOrMem), .in1(PCplus4),
//        .sel(Jump | Jalr), .out(WriteBackData)
//    );
//    branchAdder u_branchAdder (
//        .PC(PC), .imm(imm), .branchTarget(branchTarget)
//    );
//    mux2 u_pcMux1 (
//        .in0(PCplus4), .in1(branchTarget),
//        .sel(PCSrc), .out(pcBranchOrSeq)
//    );
//    mux2 u_pcMux2 (
//        .in0(pcBranchOrSeq), .in1(ALUResult),
//        .sel(Jalr), .out(nextPC)
//    );
//endmodule





//`timescale 1ns/1ps
//module TopLevelProcessor (
//    input        clk,
//    input        rst,
//    input  [15:0] sw_in,
//    output [15:0] led_out,
//    output wire [3:0]  dbgAluControl,
//    output wire        dbgRegWrite,
//    output wire        dbgMemRead,
//    output wire        dbgMemWrite,
//    output wire        dbgMemToReg,
//    output wire        dbgAluSrc,
//    output wire        dbgBranch,
//    output wire        dbgJump,
//    output wire        dbgJalr,
//    output wire        dbgZero,
//    output wire        dbgLessThan,
//    output wire [31:0] dbgPC,
//    output wire [31:0] dbgInstruction,
//    output wire [31:0] dbgAluResult       // NEW: ALU result for display
//);
//    wire [31:0] PC, PCplus4, branchTarget, nextPC, pcBranchOrSeq;
//    wire [31:0] instruction;
//    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
//    wire        Jump, Jalr;
//    wire [1:0]  ALUOp;
//    wire [31:0] ReadData1, ReadData2, imm, ALUSrcB, ALUResult;
//    wire [3:0]  ALUCtrl;
//    wire        Zero, LessThan;
//    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
//    wire [31:0] writeAluOrMem, WriteBackData;
//    wire        PCSrc;
//    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;

//    wire takeBranch = (instruction[14:12] == 3'b000) ? Zero
//                    : (instruction[14:12] == 3'b001) ? ~Zero
//                    : (instruction[14:12] == 3'b101) ? ~LessThan
//                    : 1'b0;

//    assign PCSrc = (Branch & takeBranch) | Jump;

//    // Debug signal assignments
//    assign dbgAluControl  = ALUCtrl;
//    assign dbgRegWrite    = RegWrite;
//    assign dbgMemRead     = MemRead;
//    assign dbgMemWrite    = MemWrite;
//    assign dbgMemToReg    = MemtoReg;
//    assign dbgAluSrc      = ALUSrc;
//    assign dbgBranch      = Branch;
//    assign dbgJump        = Jump;
//    assign dbgJalr        = Jalr;
//    assign dbgZero        = Zero;
//    assign dbgLessThan    = LessThan;
//    assign dbgPC          = PC;
//    assign dbgInstruction = instruction;
//    assign dbgAluResult   = ALUResult;   // NEW

//    ProgramCounter u_PC (
//        .clk(clk), .rst(rst),
//        .nextPC(nextPC), .PC(PC)
//    );
//    pcAdder u_pcAdder (
//        .PC(PC), .PCplus4(PCplus4)
//    );
//    instructionMemory u_instrMem (
//        .instAddress(PC), .instruction(instruction)
//    );
//    MainControl u_ctrl (
//        .opcode(instruction[6:0]),
//        .RegWrite(RegWrite), .ALUSrc(ALUSrc),
//        .MemRead(MemRead),   .MemWrite(MemWrite),
//        .MemtoReg(MemtoReg), .Branch(Branch),
//        .ALUOp(ALUOp),       .Jump(Jump), .Jalr(Jalr)
//    );
//    RegisterFile u_regFile (
//        .clk(clk), .rst(rst),
//        .WriteEnable(RegWrite),
//        .rs1(instruction[19:15]),
//        .rs2(instruction[24:20]),
//        .rd(instruction[11:7]),
//        .WriteData(WriteBackData),
//        .ReadData1(ReadData1), .ReadData2(ReadData2)
//    );
//    immGen u_immGen (
//        .instruction(instruction), .imm(imm)
//    );
//    mux2 u_aluSrcMux (
//        .in0(ReadData2), .in1(imm),
//        .sel(ALUSrc), .out(ALUSrcB)
//    );
//    ALUControl u_aluCtrl (
//        .ALUOp(ALUOp),
//        .funct3(instruction[14:12]),
//        .funct7(instruction[31:25]),
//        .ALUControl(ALUCtrl)
//    );
//    ALU u_alu (
//        .A(ReadData1), .B(ALUSrcB),
//        .ALUControl(ALUCtrl),
//        .ALUResult(ALUResult),
//        .Zero(Zero), .LessThan(LessThan)
//    );
//    AddressDecoder u_addrDecoder (
//        .address(ALUResult[9:8]),
//        .readEnable(MemRead),   .writeEnable(MemWrite),
//        .dataMemWrite(dataMemWrite), .dataMemRead(dataMemRead),
//        .LEDWrite(LEDWrite),    .switchReadEnable(switchReadEnable)
//    );
//    DataMemory u_dataMem (
//        .clk(clk),
//        .rst(rst),
//        .memWrite(dataMemWrite),
//        .memRead(dataMemRead),
//        .funct3(instruction[14:12]),
//        .address(ALUResult),
//        .writeData(ReadData2),
//        .readData(MemReadDataRaw)
//    );
//    switches u_switches (
//        .clk(clk), .rst(rst),
//        .btns(16'b0), .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(switchReadEnable),
//        .memAddress(ALUResult[31:2]),
//        .switches(sw_in), .readData(swReadData)
//    );
//    leds u_leds (
//        .clk(clk), .rst(rst),
//        .writeData(ReadData2),
//        .writeEnable(LEDWrite),
//        .readEnable(1'b0),
//        .memAddress(ALUResult[31:2]),
//        .readData(), .leds(led_out)
//    );
//    mux2 u_muxSwitchOrMem (
//        .in0(MemReadDataRaw), .in1(swReadData),
//        .sel(ALUResult[9] & ~ALUResult[8]),
//        .out(MemReadData)
//    );
//    mux2 u_wbMux1 (
//        .in0(ALUResult), .in1(MemReadData),
//        .sel(MemtoReg), .out(writeAluOrMem)
//    );
//    mux2 u_wbMux2 (
//        .in0(writeAluOrMem), .in1(PCplus4),
//        .sel(Jump | Jalr), .out(WriteBackData)
//    );
//    branchAdder u_branchAdder (
//        .PC(PC), .imm(imm), .branchTarget(branchTarget)
//    );
//    mux2 u_pcMux1 (
//        .in0(PCplus4), .in1(branchTarget),
//        .sel(PCSrc), .out(pcBranchOrSeq)
//    );
//    mux2 u_pcMux2 (
//        .in0(pcBranchOrSeq), .in1(ALUResult),
//        .sel(Jalr), .out(nextPC)
//    );
//endmodule






//`timescale 1ns/1ps
//module TopLevelProcessor (
//    input        clk,
//    input        rst,
//    input  [15:0] sw_in,
//    output [15:0] led_out,
//    output wire [3:0] dbgAluControl,
//    output wire       dbgRegWrite,
//    output wire       dbgMemRead,
//    output wire       dbgMemWrite,
//    output wire       dbgMemToReg,
//    output wire       dbgAluSrc,
//    output wire       dbgBranch,
//    output wire       dbgJump,
//    output wire       dbgJalr,
//    output wire       dbgZero,
//    output wire       dbgLessThan,
//    output wire [31:0] dbgPC,
//    output wire [31:0] dbgInstruction
//);
//    wire [31:0] PC, PCplus4, branchTarget, nextPC, pcBranchOrSeq;
//    wire [31:0] instruction;
//    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
//    wire        Jump, Jalr;
//    wire [1:0]  ALUOp;
//    wire [31:0] ReadData1, ReadData2, imm, ALUSrcB, ALUResult;
//    wire [3:0]  ALUCtrl;
//    wire        Zero, LessThan;
//    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
//    wire [31:0] writeAluOrMem, WriteBackData;
//    wire        PCSrc;
//    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;

//    wire takeBranch = (instruction[14:12] == 3'b000) ? Zero
//                    : (instruction[14:12] == 3'b001) ? ~Zero
//                    : (instruction[14:12] == 3'b101) ? ~LessThan
//                    : 1'b0;

//    assign PCSrc = (Branch & takeBranch) | Jump;

//    assign dbgAluControl  = ALUCtrl;
//    assign dbgRegWrite    = RegWrite;
//    assign dbgMemRead     = MemRead;
//    assign dbgMemWrite    = MemWrite;
//    assign dbgMemToReg    = MemtoReg;
//    assign dbgAluSrc      = ALUSrc;
//    assign dbgBranch      = Branch;
//    assign dbgJump        = Jump;
//    assign dbgJalr        = Jalr;
//    assign dbgZero        = Zero;
//    assign dbgLessThan    = LessThan;
//    assign dbgPC          = PC;
//    assign dbgInstruction = instruction;

//    ProgramCounter u_PC (
//        .clk(clk), .rst(rst),
//        .nextPC(nextPC), .PC(PC)
//    );
//    pcAdder u_pcAdder (
//        .PC(PC), .PCplus4(PCplus4)
//    );
//    instructionMemory u_instrMem (
//        .instAddress(PC), .instruction(instruction)
//    );
//    MainControl u_ctrl (
//        .opcode(instruction[6:0]),
//        .RegWrite(RegWrite), .ALUSrc(ALUSrc),
//        .MemRead(MemRead),   .MemWrite(MemWrite),
//        .MemtoReg(MemtoReg), .Branch(Branch),
//        .ALUOp(ALUOp),       .Jump(Jump), .Jalr(Jalr)
//    );
//    RegisterFile u_regFile (
//        .clk(clk), .rst(rst),
//        .WriteEnable(RegWrite),
//        .rs1(instruction[19:15]),
//        .rs2(instruction[24:20]),
//        .rd(instruction[11:7]),
//        .WriteData(WriteBackData),
//        .ReadData1(ReadData1), .ReadData2(ReadData2)
//    );
//    immGen u_immGen (
//        .instruction(instruction), .imm(imm)
//    );
//    mux2 u_aluSrcMux (
//        .in0(ReadData2), .in1(imm),
//        .sel(ALUSrc), .out(ALUSrcB)
//    );
//    ALUControl u_aluCtrl (
//        .ALUOp(ALUOp),
//        .funct3(instruction[14:12]),
//        .funct7(instruction[31:25]),
//        .ALUControl(ALUCtrl)
//    );
//    ALU u_alu (
//        .A(ReadData1), .B(ALUSrcB),
//        .ALUControl(ALUCtrl),
//        .ALUResult(ALUResult),
//        .Zero(Zero), .LessThan(LessThan)
//    );
//    AddressDecoder u_addrDecoder (
//        .address(ALUResult[9:8]),
//        .readEnable(MemRead),   .writeEnable(MemWrite),
//        .dataMemWrite(dataMemWrite), .dataMemRead(dataMemRead),
//        .LEDWrite(LEDWrite),    .switchReadEnable(switchReadEnable)
//    );

//    // =========================================================
//    // DATA MEMORY - full 32-bit address for byte/halfword support
//    // funct3 passed for LB/LH/LBU/LHU/SB/SH/SW
//    // =========================================================
//    DataMemory u_dataMem (
//        .clk(clk),
//        .rst(rst),
//        .memWrite(dataMemWrite),
//        .memRead(dataMemRead),
//        .funct3(instruction[14:12]),
//        .address(ALUResult),
//        .writeData(ReadData2),
//        .readData(MemReadDataRaw)
//    );

//    switches u_switches (
//        .clk(clk), .rst(rst),
//        .btns(16'b0), .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(switchReadEnable),
//        .memAddress(ALUResult[31:2]),
//        .switches(sw_in), .readData(swReadData)
//    );
//    leds u_leds (
//        .clk(clk), .rst(rst),
//        .writeData(ReadData2),
//        .writeEnable(LEDWrite),
//        .readEnable(1'b0),
//        .memAddress(ALUResult[31:2]),
//        .readData(), .leds(led_out)
//    );
//    mux2 u_muxSwitchOrMem (
//        .in0(MemReadDataRaw), .in1(swReadData),
//        .sel(ALUResult[9] & ~ALUResult[8]),
//        .out(MemReadData)
//    );
//    mux2 u_wbMux1 (
//        .in0(ALUResult), .in1(MemReadData),
//        .sel(MemtoReg), .out(writeAluOrMem)
//    );
//    mux2 u_wbMux2 (
//        .in0(writeAluOrMem), .in1(PCplus4),
//        .sel(Jump | Jalr), .out(WriteBackData)
//    );
//    branchAdder u_branchAdder (
//        .PC(PC), .imm(imm), .branchTarget(branchTarget)
//    );
//    mux2 u_pcMux1 (
//        .in0(PCplus4), .in1(branchTarget),
//        .sel(PCSrc), .out(pcBranchOrSeq)
//    );
//    mux2 u_pcMux2 (
//        .in0(pcBranchOrSeq), .in1(ALUResult),
//        .sel(Jalr), .out(nextPC)
//    );
//endmodule

////`timescale 1ns/1ps
////module TopLevelProcessor (
////    input        clk,
////    input        rst,
////    input  [15:0] sw_in,
////    output [15:0] led_out,

////    // Debug outputs for FpgaTop
////    output wire [3:0] dbgAluControl,
////    output wire       dbgRegWrite,
////    output wire       dbgMemRead,
////    output wire       dbgMemWrite,
////    output wire       dbgMemToReg,
////    output wire       dbgAluSrc,
////    output wire       dbgBranch,
////    output wire       dbgJump,
////    output wire       dbgJalr,
////    output wire       dbgZero,
////    output wire       dbgLessThan,
////    output wire [31:0] dbgPC,
////    output wire [31:0] dbgInstruction
////);

////    // =========================================================
////    // WIRES
////    // =========================================================
////    wire [31:0] PC, PCplus4, branchTarget, nextPC;
////    wire [31:0] pcBranchOrSeq;
////    wire [31:0] instruction;
////    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
////    wire        Jump, Jalr;
////    wire [1:0]  ALUOp;
////    wire [31:0] ReadData1, ReadData2;
////    wire [31:0] imm;
////    wire [3:0]  ALUCtrl;
////    wire [31:0] ALUSrcB;
////    wire [31:0] ALUResult;
////    wire        Zero, LessThan;
////    wire [31:0] MemReadData, MemReadDataRaw, swReadData;
////    wire [31:0] writeAluOrMem, WriteBackData;
////    wire        PCSrc;
////    wire        dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;

////    // =========================================================
////    // BRANCH LOGIC
////    // BEQ: branch if Zero
////    // PCSrc = 1 when branch taken OR JAL
////    // JALR handled by second PC mux
////    // =========================================================
////    wire takeBranch = (instruction[14:12] == 3'b000) ? Zero      // BEQ
////                    : (instruction[14:12] == 3'b001) ? ~Zero     // BNE
////                    : (instruction[14:12] == 3'b101) ? ~LessThan // BGE
////                    : 1'b0;

////    assign PCSrc = (Branch & takeBranch) | Jump;

////    // Debug assignments
////    assign dbgAluControl  = ALUCtrl;
////    assign dbgRegWrite    = RegWrite;
////    assign dbgMemRead     = MemRead;
////    assign dbgMemWrite    = MemWrite;
////    assign dbgMemToReg    = MemtoReg;
////    assign dbgAluSrc      = ALUSrc;
////    assign dbgBranch      = Branch;
////    assign dbgJump        = Jump;
////    assign dbgJalr        = Jalr;
////    assign dbgZero        = Zero;
////    assign dbgLessThan    = LessThan;
////    assign dbgPC          = PC;
////    assign dbgInstruction = instruction;

////    // =========================================================
////    // MODULE 1: Program Counter
////    // =========================================================
////    ProgramCounter u_PC (
////        .clk    (clk),
////        .rst    (rst),
////        .nextPC (nextPC),
////        .PC     (PC)
////    );

////    // =========================================================
////    // MODULE 2: PC + 4
////    // =========================================================
////    pcAdder u_pcAdder (
////        .PC      (PC),
////        .PCplus4 (PCplus4)
////    );

////    // =========================================================
////    // MODULE 3: Instruction Memory
////    // =========================================================
////    instructionMemory u_instrMem (
////        .instAddress (PC),
////        .instruction (instruction)
////    );

////    // =========================================================
////    // MODULE 4: Main Control Unit
////    // =========================================================
////    MainControl u_ctrl (
////        .opcode   (instruction[6:0]),
////        .RegWrite (RegWrite),
////        .ALUSrc   (ALUSrc),
////        .MemRead  (MemRead),
////        .MemWrite (MemWrite),
////        .MemtoReg (MemtoReg),
////        .Branch   (Branch),
////        .ALUOp    (ALUOp),
////        .Jump     (Jump),
////        .Jalr     (Jalr)
////    );

////    // =========================================================
////    // MODULE 5: Register File
////    // =========================================================
////    RegisterFile u_regFile (
////        .clk         (clk),
////        .rst         (rst),
////        .WriteEnable (RegWrite),
////        .rs1         (instruction[19:15]),
////        .rs2         (instruction[24:20]),
////        .rd          (instruction[11:7]),
////        .WriteData   (WriteBackData),
////        .ReadData1   (ReadData1),
////        .ReadData2   (ReadData2)
////    );

////    // =========================================================
////    // MODULE 6: Immediate Generator
////    // =========================================================
////    immGen u_immGen (
////        .instruction (instruction),
////        .imm         (imm)
////    );

////    // =========================================================
////    // MODULE 7: ALU Source Mux
////    // =========================================================
////    mux2 u_aluSrcMux (
////        .in0 (ReadData2),
////        .in1 (imm),
////        .sel (ALUSrc),
////        .out (ALUSrcB)
////    );

////    // =========================================================
////    // MODULE 8: ALU Control
////    // =========================================================
////    ALUControl u_aluCtrl (
////        .ALUOp      (ALUOp),
////        .funct3     (instruction[14:12]),
////        .funct7     (instruction[31:25]),
////        .ALUControl (ALUCtrl)
////    );

////    // =========================================================
////    // MODULE 9: ALU
////    // =========================================================
////    ALU u_alu (
////        .A          (ReadData1),
////        .B          (ALUSrcB),
////        .ALUControl (ALUCtrl),
////        .ALUResult  (ALUResult),
////        .Zero       (Zero),
////        .LessThan   (LessThan)
////    );

////    // =========================================================
////    // MODULE 10: Address Decoder
////    // =========================================================
////    AddressDecoder u_addrDecoder (
////        .address          (ALUResult[9:8]),
////        .readEnable       (MemRead),
////        .writeEnable      (MemWrite),
////        .dataMemWrite     (dataMemWrite),
////        .dataMemRead      (dataMemRead),
////        .LEDWrite         (LEDWrite),
////        .switchReadEnable (switchReadEnable)
////    );

////    // =========================================================
////    // MODULE 11: Data Memory
////    // =========================================================
////  DataMemory u_dataMem (
////    .clk       (clk),
////    .rst       (rst),
////    .address   (ALUResult[7:0]),
////    .memWrite  (dataMemWrite),
////    .writeData (ReadData2),
////    .readData  (MemReadDataRaw)
////);
////    // =========================================================
////    // MODULE 12: Switches
////    // =========================================================
////    switches u_switches (
////        .clk         (clk),
////        .rst         (rst),
////        .btns        (16'b0),
////        .writeData   (32'b0),
////        .writeEnable (1'b0),
////        .readEnable  (switchReadEnable),
////        .memAddress  (ALUResult[31:2]),
////        .switches    (sw_in),
////        .readData    (swReadData)
////    );

////    // =========================================================
////    // MODULE 13: LEDs
////    // =========================================================
////    leds u_leds (
////        .clk         (clk),
////        .rst         (rst),
////        .writeData   (ReadData2),
////        .writeEnable (LEDWrite),
////        .readEnable  (1'b0),
////        .memAddress  (ALUResult[31:2]),
////        .readData    (),
////        .leds        (led_out)
////    );

////    // =========================================================
////    // Switch vs Memory read mux
////    // =========================================================
////    mux2 u_muxSwitchOrMem (
////        .in0 (MemReadDataRaw),
////        .in1 (swReadData),
////        .sel (ALUResult[9] & ~ALUResult[8]),  // address[9:8] == 2'b10
////        .out (MemReadData)
////    );

////    // =========================================================
////    // MODULE 14: Writeback Mux 1 - ALU result vs memory data
////    // =========================================================
////    mux2 u_wbMux1 (
////        .in0 (ALUResult),
////        .in1 (MemReadData),
////        .sel (MemtoReg),
////        .out (writeAluOrMem)
////    );

////    // =========================================================
////    // MODULE 15: Writeback Mux 2 - above vs PC+4 (for JAL/JALR)
////    // =========================================================
////    mux2 u_wbMux2 (
////        .in0 (writeAluOrMem),
////        .in1 (PCplus4),
////        .sel (Jump | Jalr),
////        .out (WriteBackData)
////    );

////    // =========================================================
////    // MODULE 16: Branch Adder
////    // =========================================================
////    branchAdder u_branchAdder (
////        .PC           (PC),
////        .imm          (imm),
////        .branchTarget (branchTarget)
////    );

////    // =========================================================
////    // MODULE 17: PC Mux 1 - PC+4 vs branch/JAL target
////    // =========================================================
////    mux2 u_pcMux1 (
////        .in0 (PCplus4),
////        .in1 (branchTarget),
////        .sel (PCSrc),
////        .out (pcBranchOrSeq)
////    );

////    // =========================================================
////    // MODULE 18: PC Mux 2 - above vs ALU result (for JALR)
////    // =========================================================
////    mux2 u_pcMux2 (
////        .in0 (pcBranchOrSeq),
////        .in1 (ALUResult),
////        .sel (Jalr),
////        .out (nextPC)
////    );

////endmodule


//////`timescale 1ns/1ps

//////module TopLevelProcessor (
//////    input        clk,
//////    input        rst,
//////    input  [15:0] sw_in,
//////    output [15:0] led_out
//////);

//////    // =========================================================
//////    // WIRES
//////    // =========================================================
//////    wire [31:0] PC, PCplus4, branchTarget, nextPC;
//////    wire [31:0] instruction;
//////    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
//////    wire [1:0]  ALUOp;
//////    wire [31:0] ReadData1, ReadData2;
//////    wire [31:0] imm;
//////    wire [3:0]  ALUCtrl;
//////    wire [31:0] ALUSrcB;
//////    wire [31:0] ALUResult;
//////    wire        Zero;
//////    wire [31:0] MemReadData;
//////    wire [31:0] WriteBackData;
//////    wire        PCSrc;

//////    assign PCSrc = Branch & Zero;

//////    // =========================================================
//////    // MODULE 1: Program Counter
//////    // =========================================================
//////    ProgramCounter u_PC (
//////        .clk    (clk),
//////        .rst    (rst),
//////        .nextPC (nextPC),
//////        .PC     (PC)
//////    );

//////    // =========================================================
//////    // MODULE 2: PC + 4
//////    // =========================================================
//////    pcAdder u_pcAdder (
//////        .PC      (PC),
//////        .PCplus4 (PCplus4)
//////    );

//////    // =========================================================
//////    // MODULE 3: Instruction Memory
//////    // =========================================================
//////    instructionMemory u_instrMem (
//////        .instAddress (PC),
//////        .instruction (instruction)
//////    );

//////    // =========================================================
//////    // MODULE 4: Main Control Unit
//////    // =========================================================
//////    MainControl u_ctrl (
//////        .opcode   (instruction[6:0]),
//////        .RegWrite (RegWrite),
//////        .ALUSrc   (ALUSrc),
//////        .MemRead  (MemRead),
//////        .MemWrite (MemWrite),
//////        .MemtoReg (MemtoReg),
//////        .Branch   (Branch),
//////        .ALUOp    (ALUOp)
//////    );

//////    // =========================================================
//////    // MODULE 5: Register File
//////    // =========================================================
//////    RegisterFile u_regFile (
//////        .clk         (clk),
//////        .rst         (rst),
//////        .WriteEnable (RegWrite),
//////        .rs1         (instruction[19:15]),
//////        .rs2         (instruction[24:20]),
//////        .rd          (instruction[11:7]),
//////        .WriteData   (WriteBackData),
//////        .ReadData1   (ReadData1),
//////        .ReadData2   (ReadData2)
//////    );

//////    // =========================================================
//////    // MODULE 6: Immediate Generator
//////    // =========================================================
//////    immGen u_immGen (
//////        .instruction (instruction),
//////        .imm         (imm)
//////    );

//////    // =========================================================
//////    // MODULE 7: ALU Source Mux
//////    // ALUSrc=0 ? rs2 register, ALUSrc=1 ? immediate
//////    // =========================================================
//////    mux2 u_aluSrcMux (
//////        .in0 (ReadData2),
//////        .in1 (imm),
//////        .sel (ALUSrc),
//////        .out (ALUSrcB)
//////    );

//////    // =========================================================
//////    // MODULE 8: ALU Control
//////    // NOTE: funct7 is full [6:0] from instruction[31:25]
//////    // =========================================================
//////    ALUControl u_aluCtrl (
//////        .ALUOp      (ALUOp),
//////        .funct3     (instruction[14:12]),
//////        .funct7     (instruction[31:25]),  // full 7 bits
//////        .ALUControl (ALUCtrl)
//////    );

//////    // =========================================================
//////    // MODULE 9: ALU
//////    // =========================================================
//////    ALU u_alu (
//////        .A          (ReadData1),
//////        .B          (ALUSrcB),
//////        .ALUControl (ALUCtrl),
//////        .ALUResult  (ALUResult),
//////        .Zero       (Zero)
//////    );

//////    // =========================================================
//////    // MODULE 10: Data Memory
//////    // address is only 8-bit - use ALUResult[7:0]
//////    // memWrite (lowercase) matches your DataMemory port name
//////    // No sw_in/led_out - those connect separately via switches/leds
//////    // =========================================================
//////    DataMemory u_dataMem (
//////        .clk       (clk),
//////        .rst       (rst),
//////        .address   (ALUResult[7:0]),   // only 8 bits needed
//////        .memWrite  (MemWrite),         // lowercase matches your module
//////        .writeData (ReadData2),
//////        .readData  (MemReadData)
//////    );

//////    // =========================================================
//////    // MODULE 11: Memory-mapped Switches (Lab 5/8)
//////    // Reads physical switch state into the data memory bus
//////    // Address 0xFF00 (or whatever your lab 8 decodes) ? switch read
//////    // =========================================================
//////    wire [31:0] sw_readData;
//////    switches u_switches (
//////        .clk         (clk),
//////        .rst         (rst),
//////        .btns        (16'b0),
//////        .writeData   (32'b0),
//////        .writeEnable (1'b0),
//////        .readEnable  (MemRead),
//////        .memAddress  (ALUResult[31:2]),
//////        .switches    (sw_in),
//////        .readData    (sw_readData)
//////    );

//////    // =========================================================
//////    // MODULE 12: Memory-mapped LEDs (Lab 5/8)
//////    // Writes ALU result to physical LEDs
//////    // =========================================================
//////    leds u_leds (
//////        .clk         (clk),
//////        .rst         (rst),
//////        .writeData   (ReadData2),
//////        .writeEnable (MemWrite),
//////        .readEnable  (1'b0),
//////        .memAddress  (ALUResult[31:2]),
//////        .readData    (),
//////        .leds        (led_out)
//////    );

//////    // =========================================================
//////    // MODULE 13: Write-Back Mux
//////    // MemtoReg=0 ? ALU result, MemtoReg=1 ? memory data
//////    // =========================================================
//////    mux2 u_wbMux (
//////        .in0 (ALUResult),
//////        .in1 (MemReadData),
//////        .sel (MemtoReg),
//////        .out (WriteBackData)
//////    );

//////    // =========================================================
//////    // MODULE 14: Branch Adder
//////    // =========================================================
//////    branchAdder u_branchAdder (
//////        .PC           (PC),
//////        .imm          (imm),
//////        .branchTarget (branchTarget)
//////    );

//////    // =========================================================
//////    // MODULE 15: Next PC Mux
//////    // PCSrc=0 ? PC+4, PCSrc=1 ? branch target
//////    // =========================================================
//////    mux2 u_pcMux (
//////        .in0 (PCplus4),
//////        .in1 (branchTarget),
//////        .sel (PCSrc),
//////        .out (nextPC)
//////    );

//////endmodule



////////    // =========================================================
////////    // MODULE 13: Next PC Mux
////////    // PCSrc=0 ? next instruction (PC+4), normal flow
////////    // PCSrc=1 ? branch target, jump to new address
////////    // PCSrc is only 1 when Branch=1 AND Zero=1
////////    // =========================================================
////////    mux2 u_pcMux (
////////        .in0 (PCplus4),      // sequential next instruction
////////        .in1 (branchTarget), // branch destination
////////        .sel (PCSrc),
////////        .out (nextPC)
////////    );

////////endmodule