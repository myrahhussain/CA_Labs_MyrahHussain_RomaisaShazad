`timescale 1ns/1ps
module FpgaTop (
    input        clk,
    input        reset,       // BTNC - resets processor, not modes
    input        btnLeft,     // BTNL - resets everything
    input        btnDown,     // BTND - toggles 32-bit program output mode
    input  [15:0] switches,
    input        btnMode,     // BTNU - toggles debug/run
    input        btnAlu,      // BTNR - toggles ALU result display

    output [15:0] leds,
    output [3:0]  displayPower,
    output [6:0]  segments
);

    // =========================================================
    // Master reset
    // =========================================================
    wire masterReset = reset | btnLeft;

    // =========================================================
    // Clock Divider
    // =========================================================
    wire slowClk;
    clkDivider u_divider (
        .clkIn  (clk),
        .reset  (masterReset),
        .clkOut (slowClk)
    );

    // =========================================================
    // Debounce all buttons
    // =========================================================
    wire btnClean;
    debouncer u_debounce (
        .clk   (clk),
        .pbin  (btnMode),
        .pbout (btnClean)
    );

    wire btnAluClean;
    debouncer u_debounceAlu (
        .clk   (clk),
        .pbin  (btnAlu),
        .pbout (btnAluClean)
    );

    wire btnLeftClean;
    debouncer u_debounceLeft (
        .clk   (clk),
        .pbin  (btnLeft),
        .pbout (btnLeftClean)
    );

    wire btnDownClean;
    debouncer u_debounceDown (
        .clk   (clk),
        .pbin  (btnDown),
        .pbout (btnDownClean)
    );

    // =========================================================
    // Debug/Run mode toggle (BTNU)
    // =========================================================
    reg debugMode;
    always @(posedge clk or posedge masterReset) begin
        if (masterReset)
            debugMode <= 1'b1;
        else if (btnClean)
            debugMode <= ~debugMode;
    end

    // =========================================================
    // ALU result mode (BTNR)
    // BTNL resets it, BTNR toggles it
    // =========================================================
    reg aluMode;
    always @(posedge clk or posedge btnLeftClean) begin
        if (btnLeftClean)
            aluMode <= 1'b0;
        else if (btnAluClean)
            aluMode <= ~aluMode;
    end

    // =========================================================
    // 32-bit program output mode (BTND)
    // BTNL resets it, BTND toggles it
    // Only active in run mode
    // =========================================================
    reg mode32bit;
    always @(posedge clk or posedge btnLeftClean) begin
        if (btnLeftClean)
            mode32bit <= 1'b0;
        else if (btnDownClean)
            mode32bit <= ~mode32bit;
    end

    // =========================================================
    // Processor clock
    // =========================================================
    wire processorClk = slowClk & ~(debugMode & switches[15]);

    // =========================================================
    // Processor sees 0 switches in debug mode
    // =========================================================
    wire [15:0] processorSwitches = debugMode ? 16'b0 : switches;

    // =========================================================
    // Debug signal wires
    // =========================================================
    wire [3:0]  dbgAluControl;
    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
    wire        dbgMemToReg, dbgAluSrc, dbgBranch, dbgPCSrc, dbgBGETaken;
    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
    wire [31:0] dbgPC, dbgInstruction, dbgAluResult;
    wire [15:0] ledsOut;
    wire [31:0] ledsOut32;     // full 32-bit program output

    // =========================================================
    // Top Level Processor
    // =========================================================
    TopLevelProcessor u_processor (
        .clk           (processorClk),
        .rst           (masterReset),
        .sw_in         (processorSwitches),
        .led_out       (ledsOut),
        .led_out32     (ledsOut32),
        .dbgAluControl (dbgAluControl),
        .dbgRegWrite   (dbgRegWrite),
        .dbgMemRead    (dbgMemRead),
        .dbgMemWrite   (dbgMemWrite),
        .dbgMemToReg   (dbgMemToReg),
        .dbgAluSrc     (dbgAluSrc),
        .dbgBranch     (dbgBranch),
        .dbgPCSrc      (dbgPCSrc),
        .dbgBGETaken   (dbgBGETaken),
        .dbgJump       (dbgJump),
        .dbgJalr       (dbgJalr),
        .dbgZero       (dbgZero),
        .dbgLessThan   (dbgLessThan),
        .dbgPC         (dbgPC),
        .dbgInstruction(dbgInstruction),
        .dbgAluResult  (dbgAluResult)
    );

    // =========================================================
    // Debug LED layout
    // [15:12] aluControl
    // [11]    regWrite
    // [10]    memRead
    // [9]     memWrite
    // [8]     memToReg
    // [7]     aluSrc
    // [6]     BGETaken
    // [5]     jump
    // [4]     jalr
    // [3]     zero
    // [2]     lessThan
    // [1:0]   unused
    // =========================================================
  wire [15:0] debugLeds = {
    dbgAluControl,
    dbgRegWrite,
    dbgMemRead,
    dbgMemWrite,
    dbgMemToReg,
    dbgAluSrc,
    dbgJump,
    dbgJalr,
    dbgZero,
    dbgLessThan,
    3'b000         
};

    // =========================================================
    // Debug switch settings
    // =========================================================
    reg dbgSel0, dbgSel1, dbgSel2;
    always @(posedge clk or posedge masterReset) begin
        if (masterReset) begin
            dbgSel0 <= 0;
            dbgSel1 <= 0;
            dbgSel2 <= 0;
        end else if (debugMode) begin
            dbgSel0 <= switches[0];
            dbgSel1 <= switches[1];
            dbgSel2 <= switches[2];
        end
    end

    // =========================================================
    // ALU result split
    // =========================================================
    wire [15:0] aluLower = dbgAluResult[15:0];
    wire [15:0] aluUpper = dbgAluResult[31:16];

    // =========================================================
    // LED output priority:
    // 1. aluMode=1    ? ALU upper 16 bits (BTNR)
    // 2. mode32bit=1  ? program output lower 16 bits (BTND, run mode only)
    // 3. debugMode=1  ? control signals
    // 4. normal       ? program output lower 16 bits
    // =========================================================
    assign leds = aluMode              ? aluUpper       :
                  (mode32bit & ~debugMode) ? ledsOut32[15:0] :
                  debugMode            ? debugLeds      :
                                         ledsOut;

    // =========================================================
    // 7-Segment Display source:
    // 1. aluMode=1    ? ALU lower 16 bits (BTNR)
    // 2. mode32bit=1  ? program output upper 16 bits (BTND, run mode only)
    // 3. normal       ? instruction or PC
    // =========================================================
    wire [31:0] instrOrPc = dbgSel0 ? dbgPC : dbgInstruction;

    wire [3:0] bcdTh, bcdH, bcdT, bcdO;
    BinaryToBCD u_bcd (
        .bin      (ledsOut),
        .thousands(bcdTh),
        .hundreds (bcdH),
        .tens     (bcdT),
        .ones     (bcdO)
    );

    wire [15:0] ledsDecimal  = {bcdTh, bcdH, bcdT, bcdO};
    wire [31:0] displaySource = dbgSel2 ? {16'b0, ledsDecimal} : instrOrPc;

    wire [15:0] sevenSegSource =
        aluMode                  ? aluLower                :  // BTNR: ALU lower half
        (mode32bit & ~debugMode) ? ledsOut32[31:16]        :  // BTND: program upper 16
        (dbgSel1                 ? displaySource[31:16]    :  // normal upper half
                                   displaySource[15:0]);      // normal lower half

    SevenSegmentDriver u_sevenSeg (
        .clk          (clk),
        .reset        (masterReset),
        .hexData      (sevenSegSource),
        .displayPower (displayPower),
        .segments     (segments)
    );

endmodule
