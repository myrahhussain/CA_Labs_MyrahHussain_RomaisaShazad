`timescale 1ns/1ps

module TopLevelProcessor (
    input        clk,
    input        rst,
    input  [15:0] sw_in,
    output [15:0] led_out
);

    // =========================================================
    // WIRES
    // =========================================================
    wire [31:0] PC, PCplus4, branchTarget, nextPC;
    wire [31:0] instruction;
    wire        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0]  ALUOp;
    wire [31:0] ReadData1, ReadData2;
    wire [31:0] imm;
    wire [3:0]  ALUCtrl;
    wire [31:0] ALUSrcB;
    wire [31:0] ALUResult;
    wire        Zero;
    wire [31:0] MemReadData;
    wire [31:0] WriteBackData;
    wire        PCSrc;

    assign PCSrc = Branch & Zero;

    // =========================================================
    // MODULE 1: Program Counter
    // =========================================================
    ProgramCounter u_PC (
        .clk    (clk),
        .rst    (rst),
        .nextPC (nextPC),
        .PC     (PC)
    );

    // =========================================================
    // MODULE 2: PC + 4
    // =========================================================
    pcAdder u_pcAdder (
        .PC      (PC),
        .PCplus4 (PCplus4)
    );

    // =========================================================
    // MODULE 3: Instruction Memory
    // =========================================================
    instructionMemory u_instrMem (
        .instAddress (PC),
        .instruction (instruction)
    );

    // =========================================================
    // MODULE 4: Main Control Unit
    // =========================================================
    MainControl u_ctrl (
        .opcode   (instruction[6:0]),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    // =========================================================
    // MODULE 5: Register File
    // =========================================================
    RegisterFile u_regFile (
        .clk         (clk),
        .rst         (rst),
        .WriteEnable (RegWrite),
        .rs1         (instruction[19:15]),
        .rs2         (instruction[24:20]),
        .rd          (instruction[11:7]),
        .WriteData   (WriteBackData),
        .ReadData1   (ReadData1),
        .ReadData2   (ReadData2)
    );

    // =========================================================
    // MODULE 6: Immediate Generator
    // =========================================================
    immGen u_immGen (
        .instruction (instruction),
        .imm         (imm)
    );

    // =========================================================
    // MODULE 7: ALU Source Mux
    // ALUSrc=0 ? rs2 register, ALUSrc=1 ? immediate
    // =========================================================
    mux2 u_aluSrcMux (
        .in0 (ReadData2),
        .in1 (imm),
        .sel (ALUSrc),
        .out (ALUSrcB)
    );

    // =========================================================
    // MODULE 8: ALU Control
    // NOTE: funct7 is full [6:0] from instruction[31:25]
    // =========================================================
    ALUControl u_aluCtrl (
        .ALUOp      (ALUOp),
        .funct3     (instruction[14:12]),
        .funct7     (instruction[31:25]),  // full 7 bits
        .ALUControl (ALUCtrl)
    );

    // =========================================================
    // MODULE 9: ALU
    // =========================================================
    ALU u_alu (
        .A          (ReadData1),
        .B          (ALUSrcB),
        .ALUControl (ALUCtrl),
        .ALUResult  (ALUResult),
        .Zero       (Zero)
    );

    // =========================================================
    // MODULE 10: Data Memory
    // address is only 8-bit - use ALUResult[7:0]
    // memWrite (lowercase) matches your DataMemory port name
    // No sw_in/led_out - those connect separately via switches/leds
    // =========================================================
    DataMemory u_dataMem (
        .clk       (clk),
        .rst       (rst),
        .address   (ALUResult[7:0]),   // only 8 bits needed
        .memWrite  (MemWrite),         // lowercase matches your module
        .writeData (ReadData2),
        .readData  (MemReadData)
    );

    // =========================================================
    // MODULE 11: Memory-mapped Switches (Lab 5/8)
    // Reads physical switch state into the data memory bus
    // Address 0xFF00 (or whatever your lab 8 decodes) ? switch read
    // =========================================================
    wire [31:0] sw_readData;
    switches u_switches (
        .clk         (clk),
        .rst         (rst),
        .btns        (16'b0),
        .writeData   (32'b0),
        .writeEnable (1'b0),
        .readEnable  (MemRead),
        .memAddress  (ALUResult[31:2]),
        .switches    (sw_in),
        .readData    (sw_readData)
    );

    // =========================================================
    // MODULE 12: Memory-mapped LEDs (Lab 5/8)
    // Writes ALU result to physical LEDs
    // =========================================================
    leds u_leds (
        .clk         (clk),
        .rst         (rst),
        .writeData   (ReadData2),
        .writeEnable (MemWrite),
        .readEnable  (1'b0),
        .memAddress  (ALUResult[31:2]),
        .readData    (),
        .leds        (led_out)
    );

    // =========================================================
    // MODULE 13: Write-Back Mux
    // MemtoReg=0 ? ALU result, MemtoReg=1 ? memory data
    // =========================================================
    mux2 u_wbMux (
        .in0 (ALUResult),
        .in1 (MemReadData),
        .sel (MemtoReg),
        .out (WriteBackData)
    );

    // =========================================================
    // MODULE 14: Branch Adder
    // =========================================================
    branchAdder u_branchAdder (
        .PC           (PC),
        .imm          (imm),
        .branchTarget (branchTarget)
    );

    // =========================================================
    // MODULE 15: Next PC Mux
    // PCSrc=0 ? PC+4, PCSrc=1 ? branch target
    // =========================================================
    mux2 u_pcMux (
        .in0 (PCplus4),
        .in1 (branchTarget),
        .sel (PCSrc),
        .out (nextPC)
    );

endmodule


//`timescale 1ns/1ps

//module TopLevelProcessor (
//    input        clk,
//    input        rst,
//    // Memory-mapped I/O ports (connected to switches/LEDs on FPGA)
//    input  [15:0] sw_in,        // physical switches
//    output [15:0] led_out       // physical LEDs
//);

//    // =========================================================
//    // WIRE DECLARATIONS — these are the "wires" connecting modules
//    // =========================================================

//    // --- Program Counter wires ---
//    wire [31:0] PC;          // current PC value
//    wire [31:0] PCplus4;     // PC + 4 (next sequential instruction)
//    wire [31:0] branchTarget;// PC + (imm << 1)
//    wire [31:0] nextPC;      // chosen next PC (goes into PC register)

//    // --- Instruction Memory ---
//    wire [31:0] instruction; // 32-bit instruction fetched

//    // --- Control signals (from Control Unit) ---
//    wire        Branch;      // 1 = branch instruction
//    wire        MemRead;     // 1 = load from data memory
//    wire        MemtoReg;    // 1 = write memory data to reg, 0 = ALU result
//    wire [1:0]  ALUOp;       // tells ALU Control what type of instruction
//    wire        MemWrite;    // 1 = store to data memory
//    wire        ALUSrc;      // 1 = use immediate, 0 = use rs2
//    wire        RegWrite;    // 1 = write result back to register file

//    // --- Register File wires ---
//    wire [31:0] ReadData1;   // rs1 value
//    wire [31:0] ReadData2;   // rs2 value

//    // --- Immediate Generator ---
//    wire [31:0] imm;         // sign-extended immediate

//    // --- ALU wires ---
//    wire [3:0]  ALUCtrl;     // operation code for ALU (from ALU Control)
//    wire [31:0] ALUSrcB;     // mux output: rs2 OR immediate
//    wire [31:0] ALUResult;   // result of ALU operation
//    wire        Zero;        // 1 if ALUResult == 0 (used for branches)

//    // --- Data Memory wires ---
//    wire [31:0] MemReadData; // data read from memory (for lw)

//    // --- Write-back mux ---
//    wire [31:0] WriteBackData; // data written back to register file

//    // --- PCSrc: branch taken? ---
//    // Branch is taken only if it's a branch instruction AND Zero flag is set
//    wire        PCSrc;
//    assign PCSrc = Branch & Zero;

//    // =========================================================
//    // MODULE 1: Program Counter
//    // Holds current instruction address, updates every clock cycle
//    // =========================================================
//    ProgramCounter u_PC (
//        .clk    (clk),
//        .rst    (rst),
//        .nextPC (nextPC),
//        .PC     (PC)
//    );

//    // =========================================================
//    // MODULE 2: PC Adder — computes PC + 4
//    // Always running, feeds into the mux for next PC
//    // =========================================================
//    pcAdder u_pcAdder (
//        .PC      (PC),
//        .PCplus4 (PCplus4)
//    );

//    // =========================================================
//    // MODULE 3: Instruction Memory
//    // Takes PC as address, outputs the 32-bit instruction stored there
//    // This is where your Lab 10 assembly program lives
//    // =========================================================
//    instructionMemory u_instrMem (
//        .instAddress (PC),
//        .instruction (instruction)
//    );

//    // =========================================================
//    // MODULE 4: Control Unit
//    // Reads the opcode (bits [6:0]) and generates all control signals
//    // Different opcodes ? different combinations of control signals
//    // =========================================================
//    MainControl u_ctrl (
//        .opcode   (instruction[6:0]),
//        .Branch   (Branch),
//        .MemRead  (MemRead),
//        .MemtoReg (MemtoReg),
//        .ALUOp    (ALUOp),
//        .MemWrite (MemWrite),
//        .ALUSrc   (ALUSrc),
//        .RegWrite (RegWrite)
//    );

//    // =========================================================
//    // MODULE 5: Register File
//    // Reads two registers simultaneously (rs1, rs2)
//    // Writes back result to rd on rising clock edge (if RegWrite=1)
//    // =========================================================
//    RegisterFile u_regFile (
//        .clk         (clk),
//        .rst         (rst),
//        .WriteEnable (RegWrite),
//        .rs1         (instruction[19:15]),  // rs1 field
//        .rs2         (instruction[24:20]),  // rs2 field
//        .rd          (instruction[11:7]),   // destination register
//        .WriteData   (WriteBackData),       // data to write back
//        .ReadData1   (ReadData1),
//        .ReadData2   (ReadData2)
//    );

//    // =========================================================
//    // MODULE 6: Immediate Generator
//    // Extracts and sign-extends the immediate value from the instruction
//    // Handles I-type, S-type, and B-type formats
//    // =========================================================
//    immGen u_immGen (
//        .instruction (instruction),
//        .imm         (imm)
//    );

//    // =========================================================
//    // MODULE 7: ALU Source Mux
//    // Selects what goes into ALU input B:
//    //   ALUSrc=0 ? use register rs2 value (R-type instructions)
//    //   ALUSrc=1 ? use immediate value (I-type, S-type, B-type)
//    // =========================================================
//    mux2 u_aluSrcMux (
//        .in0 (ReadData2),  // rs2 register value
//        .in1 (imm),        // immediate from immGen
//        .sel (ALUSrc),
//        .out (ALUSrcB)
//    );

//    // =========================================================
//    // MODULE 8: ALU Control
//    // Takes ALUOp from control unit + funct3/funct7 from instruction
//    // Outputs the specific 4-bit operation code for the ALU
//    // e.g. ALUOp=10 + funct3=000 ? ADD (for R-type add)
//    // =========================================================
//    ALUControl u_aluCtrl (
//        .ALUOp   (ALUOp),
//        .funct3  (instruction[14:12]),
//        .funct7  (instruction[30]),
//        .ALUCtrl (ALUCtrl)
//    );

//    // =========================================================
//    // MODULE 9: ALU
//    // Performs the actual computation
//    // A = rs1, B = ALUSrcB (rs2 or immediate)
//    // Zero flag used for branch decision
//    // =========================================================
//    ALU u_alu (
//        .A          (ReadData1),
//        .B          (ALUSrcB),
//        .ALUControl (ALUCtrl),
//        .ALUResult  (ALUResult),
//        .Zero       (Zero)
//    );

//    // =========================================================
//    // MODULE 10: Data Memory
//    // Used for lw (load) and sw (store) instructions
//    // Address = ALUResult (base + offset already computed by ALU)
//    // On lw: reads from that address ? MemReadData
//    // On sw: writes ReadData2 to that address
//    // This connects to your memory-mapped switches and LEDs from Lab 8
//    // =========================================================
//    DataMemory u_dataMem (
//        .clk        (clk),
//        .rst        (rst),
//        .MemWrite   (MemWrite),
//        .address    (ALUResult),
//        .writeData  (ReadData2),
//        .readData   (MemReadData),
//        // Memory-mapped I/O
//        .sw_in      (sw_in),
//        .led_out    (led_out)
//    );

//    // =========================================================
//    // MODULE 11: Write-Back Mux
//    // Selects what gets written back to the register file:
//    //   MemtoReg=0 ? ALU result (for R-type, I-type arithmetic)
//    //   MemtoReg=1 ? data from memory (for lw instruction)
//    // =========================================================
//    mux2 u_wbMux (
//        .in0 (ALUResult),    // from ALU
//        .in1 (MemReadData),  // from data memory (lw)
//        .sel (MemtoReg),
//        .out (WriteBackData)
//    );

//    // =========================================================
//    // MODULE 12: Branch Adder
//    // Computes branch target: PC + (imm << 1)
//    // Only used when branch is taken
//    // =========================================================
//    branchAdder u_branchAdder (
//        .PC          (PC),
//        .imm         (imm),
//        .branchTarget(branchTarget)
//    );

//    // =========================================================
//    // MODULE 13: Next PC Mux
//    // PCSrc=0 ? next instruction (PC+4), normal flow
//    // PCSrc=1 ? branch target, jump to new address
//    // PCSrc is only 1 when Branch=1 AND Zero=1
//    // =========================================================
//    mux2 u_pcMux (
//        .in0 (PCplus4),      // sequential next instruction
//        .in1 (branchTarget), // branch destination
//        .sel (PCSrc),
//        .out (nextPC)
//    );

//endmodule