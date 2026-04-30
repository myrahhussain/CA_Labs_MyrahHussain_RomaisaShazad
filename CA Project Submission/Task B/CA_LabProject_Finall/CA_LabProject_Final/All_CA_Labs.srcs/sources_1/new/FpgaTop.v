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
        dbgBGETaken,
        dbgJump,
        dbgJalr,
        dbgZero,
        dbgLessThan,
        2'b00
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


//`timescale 1ns/1ps
//module FpgaTop (
//    input        clk,
//    input        reset,       // BTNC - resets everything EXCEPT aluMode
//    input        btnLeft,     // BTNL - resets EVERYTHING including aluMode
//    input  [15:0] switches,
//    input        btnMode,     // BTNU - toggles debug/run mode
//    input        btnAlu,      // BTNR - toggles ALU result display

//    output [15:0] leds,
//    output [3:0]  displayPower,
//    output [6:0]  segments
//);

//    // =========================================================
//    // Master reset = BTNC OR BTNL
//    // BTNC resets processor but NOT aluMode
//    // BTNL resets everything including aluMode
//    // =========================================================
//    wire masterReset = reset | btnLeft;

//    // =========================================================
//    // Clock Divider - slows 100MHz to ~2Hz for visible output
//    // =========================================================
//    wire slowClk;
//    clkDivider u_divider (
//        .clkIn  (clk),
//        .reset  (masterReset),
//        .clkOut (slowClk)
//    );

//    // =========================================================
//    // Debounce mode button
//    // =========================================================
//    wire btnClean;
//    debouncer u_debounce (
//        .clk   (clk),
//        .pbin  (btnMode),
//        .pbout (btnClean)
//    );

//    // =========================================================
//    // Debounce ALU button
//    // =========================================================
//    wire btnAluClean;
//    debouncer u_debounceAlu (
//        .clk   (clk),
//        .pbin  (btnAlu),
//        .pbout (btnAluClean)
//    );

//    // =========================================================
//    // Debounce Left button
//    // =========================================================
//    wire btnLeftClean;
//    debouncer u_debounceLeft (
//        .clk   (clk),
//        .pbin  (btnLeft),
//        .pbout (btnLeftClean)
//    );

//    // =========================================================
//    // Debug/Run mode toggle
//    // masterReset starts in debug mode
//    // btnMode toggles between debug and run
//    // =========================================================
//    reg debugMode;
//    always @(posedge clk or posedge masterReset) begin
//        if (masterReset)
//            debugMode <= 1'b1;
//        else if (btnClean)
//            debugMode <= ~debugMode;
//    end

//    // =========================================================
//    // ALU result mode toggle
//    // BTNC reset does NOT reset aluMode (stays as is)
//    // BTNL reset DOES reset aluMode back to OFF
//    // BTNR toggles aluMode ON/OFF
//    // =========================================================
//    reg aluMode;
//    always @(posedge clk or posedge btnLeftClean) begin
//        if (btnLeftClean)
//            aluMode <= 1'b0;    // BTNL resets aluMode to OFF
//        else if (btnAluClean)
//            aluMode <= ~aluMode;
//    end

//    // =========================================================
//    // Processor clock - freeze when debug mode + sw[15] high
//    // =========================================================
//    wire processorClk = slowClk & ~(debugMode & switches[15]);

//    // =========================================================
//    // Processor sees 0 switches in debug mode
//    // =========================================================
//    wire [15:0] processorSwitches = debugMode ? 16'b0 : switches;

//    // =========================================================
//    // Debug signal wires
//    // =========================================================
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
//    wire        dbgMemToReg, dbgAluSrc, dbgBranch;
//    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
//    wire [31:0] dbgPC, dbgInstruction, dbgAluResult;
//    wire [15:0] ledsOut;

//    // =========================================================
//    // Top Level Processor
//    // =========================================================
//    TopLevelProcessor u_processor (
//        .clk           (processorClk),
//        .rst           (masterReset),
//        .sw_in         (processorSwitches),
//        .led_out       (ledsOut),
//        .dbgAluControl (dbgAluControl),
//        .dbgRegWrite   (dbgRegWrite),
//        .dbgMemRead    (dbgMemRead),
//        .dbgMemWrite   (dbgMemWrite),
//        .dbgMemToReg   (dbgMemToReg),
//        .dbgAluSrc     (dbgAluSrc),
//        .dbgBranch     (dbgBranch),
//        .dbgJump       (dbgJump),
//        .dbgJalr       (dbgJalr),
//        .dbgZero       (dbgZero),
//        .dbgLessThan   (dbgLessThan),
//        .dbgPC         (dbgPC),
//        .dbgInstruction(dbgInstruction),
//        .dbgAluResult  (dbgAluResult)
//    );

//    // =========================================================
//    // Debug LED layout
//    // [15:12] aluControl
//    // [11]    regWrite
//    // [10]    memRead
//    // [9]     memWrite
//    // [8]     memToReg
//    // [7]     aluSrc
//    // [6]     branch
//    // [5]     jump
//    // [4]     jalr
//    // [3]     zero
//    // [2]     lessThan
//    // [1:0]   unused
//    // =========================================================
//    wire [15:0] debugLeds = {
//        dbgAluControl,
//        dbgRegWrite,
//        dbgMemRead,
//        dbgMemWrite,
//        dbgMemToReg,
//        dbgAluSrc,
//        dbgBranch,
//        dbgJump,
//        dbgJalr,
//        dbgZero,
//        dbgLessThan,
//        2'b00
//    };

//    // =========================================================
//    // Debug switch settings - only latched in debug mode
//    // sw[0] -> instruction vs PC
//    // sw[1] -> upper vs lower 16 bits
//    // sw[2] -> decimal mode
//    // =========================================================
//    reg dbgSel0, dbgSel1, dbgSel2;
//    always @(posedge clk or posedge masterReset) begin
//        if (masterReset) begin
//            dbgSel0 <= 0;
//            dbgSel1 <= 0;
//            dbgSel2 <= 0;
//        end else if (debugMode) begin
//            dbgSel0 <= switches[0];
//            dbgSel1 <= switches[1];
//            dbgSel2 <= switches[2];
//        end
//    end

//    // =========================================================
//    // ALU result split into halves
//    // =========================================================
//    wire [15:0] aluLower = dbgAluResult[15:0];
//    wire [15:0] aluUpper = dbgAluResult[31:16];

//    // =========================================================
//    // LED output:
//    // aluMode=1  -> show ALU upper 16 bits (LEDs)
//    // aluMode=0, debug mode -> show control signals
//    // aluMode=0, run mode   -> show program output
//    // =========================================================
//    assign leds = aluMode   ? aluUpper  :
//                  debugMode ? debugLeds :
//                              ledsOut;

//    // =========================================================
//    // 7-Segment Display
//    // aluMode=1  -> show ALU lower 16 bits (actual values)
//    // aluMode=0  -> normal instruction/PC display
//    // =========================================================
//    wire [31:0] instrOrPc = dbgSel0 ? dbgPC : dbgInstruction;

//    wire [3:0] bcdTh, bcdH, bcdT, bcdO;
//    BinaryToBCD u_bcd (
//        .bin      (ledsOut),
//        .thousands(bcdTh),
//        .hundreds (bcdH),
//        .tens     (bcdT),
//        .ones     (bcdO)
//    );

//    wire [15:0] ledsDecimal  = {bcdTh, bcdH, bcdT, bcdO};
//    wire [31:0] displaySource = dbgSel2 ? {16'b0, ledsDecimal} : instrOrPc;

//    // 7seg source:
//    // aluMode=1  -> ALU lower half (actual values easy to read)
//    // aluMode=0  -> normal instruction/PC display
//    wire [15:0] sevenSegSource = aluMode ? aluLower
//                               : (dbgSel1 ? displaySource[31:16]
//                                          : displaySource[15:0]);

//    SevenSegmentDriver u_sevenSeg (
//        .clk          (clk),
//        .reset        (masterReset),
//        .hexData      (sevenSegSource),
//        .displayPower (displayPower),
//        .segments     (segments)
//    );

//endmodule

//`timescale 1ns/1ps
//module FpgaTop (
//    input        clk,
//    input        reset,
//    input  [15:0] switches,
//    input        btnMode,
//    input        btnAlu,        // NEW: BTNR - toggles ALU result display

//    output [15:0] leds,
//    output [3:0]  displayPower,
//    output [6:0]  segments
//);

//    // =========================================================
//    // Clock Divider - slows 100MHz to ~2Hz for visible output
//    // =========================================================
//    wire slowClk;
//    clkDivider u_divider (
//        .clkIn  (clk),
//        .reset  (reset),
//        .clkOut (slowClk)
//    );

//    // =========================================================
//    // Debounce mode button
//    // =========================================================
//    wire btnClean;
//    debouncer u_debounce (
//        .clk   (clk),
//        .pbin  (btnMode),
//        .pbout (btnClean)
//    );

//    // =========================================================
//    // Debounce ALU button - NEW
//    // =========================================================
//    wire btnAluClean;
//    debouncer u_debounceAlu (
//        .clk   (clk),
//        .pbin  (btnAlu),
//        .pbout (btnAluClean)
//    );

//    // =========================================================
//    // Debug/Run mode toggle
//    // Reset starts in debug mode
//    // btnMode toggles between debug and run
//    // =========================================================
//    reg debugMode;
//    always @(posedge clk or posedge reset) begin
//        if (reset)
//            debugMode <= 1'b1;
//        else if (btnClean)
//            debugMode <= ~debugMode;
//    end

//    // =========================================================
//    // ALU result mode toggle - NEW
//    // Reset starts with ALU mode OFF
//    // btnAlu toggles ALU result display on/off
//    // Works in BOTH run mode and debug mode
//    // =========================================================
//    reg aluMode;
//    always @(posedge clk) begin
//    if (btnAluClean)
//        aluMode <= ~aluMode;
//    end

//    // =========================================================
//    // Processor clock - freeze when debug mode + sw[15] high
//    // =========================================================
//    wire processorClk = slowClk & ~(debugMode & switches[15]);

//    // =========================================================
//    // Processor sees 0 switches in debug mode
//    // =========================================================
//    wire [15:0] processorSwitches = debugMode ? 16'b0 : switches;

//    // =========================================================
//    // Debug signal wires
//    // =========================================================
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
//    wire        dbgMemToReg, dbgAluSrc, dbgBranch;
//    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
//    wire [31:0] dbgPC, dbgInstruction, dbgAluResult;
//    wire [15:0] ledsOut;

//    // =========================================================
//    // Top Level Processor
//    // =========================================================
//    TopLevelProcessor u_processor (
//        .clk           (processorClk),
//        .rst           (reset),
//        .sw_in         (processorSwitches),
//        .led_out       (ledsOut),
//        .dbgAluControl (dbgAluControl),
//        .dbgRegWrite   (dbgRegWrite),
//        .dbgMemRead    (dbgMemRead),
//        .dbgMemWrite   (dbgMemWrite),
//        .dbgMemToReg   (dbgMemToReg),
//        .dbgAluSrc     (dbgAluSrc),
//        .dbgBranch     (dbgBranch),
//        .dbgJump       (dbgJump),
//        .dbgJalr       (dbgJalr),
//        .dbgZero       (dbgZero),
//        .dbgLessThan   (dbgLessThan),
//        .dbgPC         (dbgPC),
//        .dbgInstruction(dbgInstruction),
//        .dbgAluResult  (dbgAluResult)
//    );

//    // =========================================================
//    // Debug LED layout
//    // [15:12] aluControl
//    // [11]    regWrite
//    // [10]    memRead
//    // [9]     memWrite
//    // [8]     memToReg
//    // [7]     aluSrc
//    // [6]     branch
//    // [5]     jump
//    // [4]     jalr
//    // [3]     zero
//    // [2]     lessThan
//    // [1:0]   unused
//    // =========================================================
//    wire [15:0] debugLeds = {
//        dbgAluControl,
//        dbgRegWrite,
//        dbgMemRead,
//        dbgMemWrite,
//        dbgMemToReg,
//        dbgAluSrc,
//        dbgBranch,
//        dbgJump,
//        dbgJalr,
//        dbgZero,
//        dbgLessThan,
//        2'b00
//    };

//    // =========================================================
//    // Debug switch settings - only latched in debug mode
//    // sw[0] -> instruction vs PC
//    // sw[1] -> upper vs lower 16 bits
//    // sw[2] -> decimal mode
//    // =========================================================
//    reg dbgSel0, dbgSel1, dbgSel2;
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            dbgSel0 <= 0;
//            dbgSel1 <= 0;
//            dbgSel2 <= 0;
//        end else if (debugMode) begin
//            dbgSel0 <= switches[0];
//            dbgSel1 <= switches[1];
//            dbgSel2 <= switches[2];
//        end
//    end

//    // =========================================================
//    // ALU result split into halves
//    // =========================================================
//    wire [15:0] aluLower = dbgAluResult[15:0];
//    wire [15:0] aluUpper = dbgAluResult[31:16];

//    // =========================================================
//    // LED output:
//    // aluMode=1  -> ALWAYS show ALU lower 16 bits
//    //               (overrides both debug and run mode)
//    // aluMode=0, debug mode -> show control signals
//    // aluMode=0, run mode   -> show program output
//    // =========================================================
//    assign leds = aluMode    ? aluUpper  :
//                  debugMode  ? debugLeds :
//                               ledsOut;

//    // =========================================================
//    // 7-Segment Display
//    // aluMode=1  -> show ALU upper 16 bits
//    // aluMode=0  -> normal instruction/PC display
//    // sw[0]=0 -> instruction, sw[0]=1 -> PC
//    // sw[1]=0 -> lower 16, sw[1]=1 -> upper 16
//    // sw[2]=1 -> decimal LED value
//    // =========================================================
//    wire [31:0] instrOrPc = dbgSel0 ? dbgPC : dbgInstruction;

//    wire [3:0] bcdTh, bcdH, bcdT, bcdO;
//    BinaryToBCD u_bcd (
//        .bin      (ledsOut),
//        .thousands(bcdTh),
//        .hundreds (bcdH),
//        .tens     (bcdT),
//        .ones     (bcdO)
//    );

//    wire [15:0] ledsDecimal  = {bcdTh, bcdH, bcdT, bcdO};
//    wire [31:0] displaySource = dbgSel2 ? {16'b0, ledsDecimal} : instrOrPc;

//    // 7seg source:
//    // aluMode=1  -> ALU upper half
//    // aluMode=0  -> normal instruction/PC display
//    wire [15:0] sevenSegSource = aluMode ? aluLower
//                               : (dbgSel1 ? displaySource[31:16]
//                                          : displaySource[15:0]);

//    SevenSegmentDriver u_sevenSeg (
//        .clk          (clk),
//        .reset        (reset),
//        .hexData      (sevenSegSource),
//        .displayPower (displayPower),
//        .segments     (segments)
//    );

//endmodule



//`timescale 1ns/1ps
//module FpgaTop (
//    input        clk,
//    input        reset,
//    input  [15:0] switches,
//    input        btnMode,

//    output [15:0] leds,
//    output [3:0]  displayPower,
//    output [6:0]  segments
//);

//    // =========================================================
//    // Clock Divider - slows 100MHz to ~2Hz for visible output
//    // =========================================================
//    wire slowClk;
//    clkDivider u_divider (
//        .clkIn  (clk),
//        .reset  (reset),
//        .clkOut (slowClk)
//    );

//    // =========================================================
//    // Debounce mode button
//    // =========================================================
//    wire btnClean;
//    debouncer u_debounce (
//        .clk   (clk),
//        .pbin  (btnMode),
//        .pbout (btnClean)
//    );

//    // =========================================================
//    // Debug/Run mode toggle
//    // Reset starts in debug mode
//    // btnMode toggles between debug and run
//    // =========================================================
//    reg debugMode;
//    always @(posedge clk or posedge reset) begin
//        if (reset)
//            debugMode <= 1'b1;
//        else if (btnClean)
//            debugMode <= ~debugMode;
//    end

//    // =========================================================
//    // Processor clock - freeze when debug mode + sw[15] high
//    // =========================================================
//    wire processorClk = slowClk & ~(debugMode & switches[15]);

//    // =========================================================
//    // Processor sees 0 switches in debug mode
//    // =========================================================
//    wire [15:0] processorSwitches = debugMode ? 16'b0 : switches;

//    // =========================================================
//    // Debug signal wires
//    // =========================================================
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
//    wire        dbgMemToReg, dbgAluSrc, dbgBranch;
//    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
//    wire [31:0] dbgPC, dbgInstruction, dbgAluResult;
//    wire [15:0] ledsOut;

//    // =========================================================
//    // Top Level Processor
//    // =========================================================
//    TopLevelProcessor u_processor (
//        .clk           (processorClk),
//        .rst           (reset),
//        .sw_in         (processorSwitches),
//        .led_out       (ledsOut),
//        .dbgAluControl (dbgAluControl),
//        .dbgRegWrite   (dbgRegWrite),
//        .dbgMemRead    (dbgMemRead),
//        .dbgMemWrite   (dbgMemWrite),
//        .dbgMemToReg   (dbgMemToReg),
//        .dbgAluSrc     (dbgAluSrc),
//        .dbgBranch     (dbgBranch),
//        .dbgJump       (dbgJump),
//        .dbgJalr       (dbgJalr),
//        .dbgZero       (dbgZero),
//        .dbgLessThan   (dbgLessThan),
//        .dbgPC         (dbgPC),
//        .dbgInstruction(dbgInstruction),
//        .dbgAluResult  (dbgAluResult)
//    );

//    // =========================================================
//    // Debug LED layout
//    // [15:12] aluControl
//    // [11]    regWrite
//    // [10]    memRead
//    // [9]     memWrite
//    // [8]     memToReg
//    // [7]     aluSrc
//    // [6]     branch
//    // [5]     jump
//    // [4]     jalr
//    // [3]     zero
//    // [2]     lessThan
//    // [1:0]   unused
//    // =========================================================
//    wire [15:0] debugLeds = {
//        dbgAluControl,
//        dbgRegWrite,
//        dbgMemRead,
//        dbgMemWrite,
//        dbgMemToReg,
//        dbgAluSrc,
//        dbgBranch,
//        dbgJump,
//        dbgJalr,
//        dbgZero,
//        dbgLessThan,
//        2'b00
//    };

//    // =========================================================
//    // Debug switch settings - only latched in debug mode
//    // sw[0] -> instruction vs PC
//    // sw[1] -> upper vs lower 16 bits
//    // sw[2] -> decimal mode
//    // =========================================================
//    reg dbgSel0, dbgSel1, dbgSel2;
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            dbgSel0 <= 0;
//            dbgSel1 <= 0;
//            dbgSel2 <= 0;
//        end else if (debugMode) begin
//            dbgSel0 <= switches[0];
//            dbgSel1 <= switches[1];
//            dbgSel2 <= switches[2];
//        end
//    end

//    // =========================================================
//    // ALU result split into halves
//    // =========================================================
//    wire [15:0] aluLower = dbgAluResult[15:0];
//    wire [15:0] aluUpper = dbgAluResult[31:16];

//    // =========================================================
//    // LED output:
//    // debug mode + sw[3]=1  -> show ALU lower 16 bits
//    // debug mode + sw[3]=0  -> show control signals
//    // run mode              -> ALWAYS show program output (unaffected)
//    // =========================================================
//    assign leds = debugMode ? (switches[3] ? aluLower : debugLeds)
//                            : ledsOut;

//    // =========================================================
//    // 7-Segment Display
//    // debug mode + sw[3]=1  -> show ALU upper 16 bits
//    // debug mode + sw[3]=0  -> show instruction or PC
//    // run mode              -> show instruction or PC as before
//    // sw[0]=0 -> instruction, sw[0]=1 -> PC
//    // sw[1]=0 -> lower 16, sw[1]=1 -> upper 16
//    // sw[2]=1 -> decimal LED value
//    // =========================================================
//    wire [31:0] instrOrPc = dbgSel0 ? dbgPC : dbgInstruction;

//    wire [3:0] bcdTh, bcdH, bcdT, bcdO;
//    BinaryToBCD u_bcd (
//        .bin      (ledsOut),
//        .thousands(bcdTh),
//        .hundreds (bcdH),
//        .tens     (bcdT),
//        .ones     (bcdO)
//    );

//    wire [15:0] ledsDecimal  = {bcdTh, bcdH, bcdT, bcdO};
//    wire [31:0] displaySource = dbgSel2 ? {16'b0, ledsDecimal} : instrOrPc;

//    // 7seg source:
//    // debug mode + sw[3]=1  -> ALU upper half (live, not latched)
//    // everything else       -> normal instruction/PC display
//    wire [15:0] sevenSegSource = (debugMode & switches[3]) ? aluUpper
//                               : (dbgSel1 ? displaySource[31:16]
//                                          : displaySource[15:0]);

//    SevenSegmentDriver u_sevenSeg (
//        .clk          (clk),
//        .reset        (reset),
//        .hexData      (sevenSegSource),
//        .displayPower (displayPower),
//        .segments     (segments)
//    );

//endmodule

//`timescale 1ns/1ps
//module FpgaTop (
//    input        clk,
//    input        reset,
//    input  [15:0] switches,
//    input        btnMode,

//    output [15:0] leds,
//    output [3:0]  displayPower,
//    output [6:0]  segments
//);

//    // =========================================================
//    // Clock Divider - slows 100MHz to ~2Hz for visible output
//    // =========================================================
//    wire slowClk;
//    clkDivider u_divider (
//        .clkIn  (clk),
//        .reset  (reset),
//        .clkOut (slowClk)
//    );

//    // =========================================================
//    // Debounce mode button
//    // =========================================================
//    wire btnClean;
//    debouncer u_debounce (
//        .clk   (clk),
//        .pbin  (btnMode),
//        .pbout (btnClean)
//    );

//    // =========================================================
//    // Debug/Run mode toggle
//    // Reset starts in debug mode
//    // btnMode toggles between debug and run
//    // =========================================================
//    reg debugMode;
//    always @(posedge clk or posedge reset) begin
//        if (reset)
//            debugMode <= 1'b1;
//        else if (btnClean)
//            debugMode <= ~debugMode;
//    end

//    // =========================================================
//    // Processor clock - freeze when debug mode + sw[15] high
//    // =========================================================
//    wire processorClk = slowClk & ~(debugMode & switches[15]);

//    // =========================================================
//    // Processor sees 0 switches in debug mode
//    // =========================================================
//    wire [15:0] processorSwitches = debugMode ? 16'b0 : switches;

//    // =========================================================
//    // Debug signal wires
//    // =========================================================
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
//    wire        dbgMemToReg, dbgAluSrc, dbgBranch;
//    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
//    wire [31:0] dbgPC, dbgInstruction, dbgAluResult;  // NEW: dbgAluResult
//    wire [15:0] ledsOut;

//    // =========================================================
//    // Top Level Processor
//    // =========================================================
//    TopLevelProcessor u_processor (
//        .clk           (processorClk),
//        .rst           (reset),
//        .sw_in         (processorSwitches),
//        .led_out       (ledsOut),
//        .dbgAluControl (dbgAluControl),
//        .dbgRegWrite   (dbgRegWrite),
//        .dbgMemRead    (dbgMemRead),
//        .dbgMemWrite   (dbgMemWrite),
//        .dbgMemToReg   (dbgMemToReg),
//        .dbgAluSrc     (dbgAluSrc),
//        .dbgBranch     (dbgBranch),
//        .dbgJump       (dbgJump),
//        .dbgJalr       (dbgJalr),
//        .dbgZero       (dbgZero),
//        .dbgLessThan   (dbgLessThan),
//        .dbgPC         (dbgPC),
//        .dbgInstruction(dbgInstruction),
//        .dbgAluResult  (dbgAluResult)    // NEW
//    );

//    // =========================================================
//    // Debug LED layout
//    // [15:12] aluControl
//    // [11]    regWrite
//    // [10]    memRead
//    // [9]     memWrite
//    // [8]     memToReg
//    // [7]     aluSrc
//    // [6]     branch
//    // [5]     jump
//    // [4]     jalr
//    // [3]     zero
//    // [2]     lessThan
//    // [1:0]   unused
//    // =========================================================
//    wire [15:0] debugLeds = {
//        dbgAluControl,
//        dbgRegWrite,
//        dbgMemRead,
//        dbgMemWrite,
//        dbgMemToReg,
//        dbgAluSrc,
//        dbgBranch,
//        dbgJump,
//        dbgJalr,
//        dbgZero,
//        dbgLessThan,
//        2'b00
//    };

//    // =========================================================
//    // Latch debug switch settings
//    // sw[0] -> instruction vs PC
//    // sw[1] -> upper vs lower 16 bits
//    // sw[2] -> decimal mode
//    // sw[3] -> ALU result mode (NEW)
//    // =========================================================
//    reg dbgSel0, dbgSel1, dbgSel2, dbgSel3;
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            dbgSel0 <= 0;
//            dbgSel1 <= 0;
//            dbgSel2 <= 0;
//            dbgSel3 <= 0;   // NEW
//        end else if (debugMode) begin
//            dbgSel0 <= switches[0];
//            dbgSel1 <= switches[1];
//            dbgSel2 <= switches[2];
//            dbgSel3 <= switches[3];  // NEW
//        end
//    end

//    // =========================================================
//    // 7-Segment Display source selection
//    // dbgSel3=1 -> show ALU result upper 16 bits
//    // dbgSel2=1 -> show LED value in BCD decimal
//    // dbgSel0=0 -> show instruction, dbgSel0=1 -> show PC
//    // dbgSel1=0 -> lower 16 bits, dbgSel1=1 -> upper 16 bits
//    // =========================================================
//    wire [31:0] instrOrPc = dbgSel0 ? dbgPC : dbgInstruction;

//    wire [3:0] bcdTh, bcdH, bcdT, bcdO;
//    BinaryToBCD u_bcd (
//        .bin      (ledsOut),
//        .thousands(bcdTh),
//        .hundreds (bcdH),
//        .tens     (bcdT),
//        .ones     (bcdO)
//    );

//    wire [15:0] ledsDecimal   = {bcdTh, bcdH, bcdT, bcdO};
//    wire [31:0] displaySource  = dbgSel2 ? {16'b0, ledsDecimal} : instrOrPc;

//    // ALU result split into halves
//    wire [15:0] aluLower = dbgAluResult[15:0];
//    wire [15:0] aluUpper = dbgAluResult[31:16];

//    // 7seg source:
//    // dbgSel3=1 -> ALU upper half
//    // dbgSel3=0 -> normal (instruction/PC upper or lower based on dbgSel1)
//    wire [15:0] sevenSegSource = dbgSel3 ? aluUpper
//                               : (dbgSel1 ? displaySource[31:16]
//                                          : displaySource[15:0]);

//    SevenSegmentDriver u_sevenSeg (
//        .clk          (clk),
//        .reset        (reset),
//        .hexData      (sevenSegSource),
//        .displayPower (displayPower),
//        .segments     (segments)
//    );

//    // =========================================================
//    // LED output selection:
//    // debug mode    -> show control signals
//    // run + sel3=1  -> show ALU result lower 16 bits
//    // run + sel3=0  -> show program output
//    // =========================================================
//    assign leds = debugMode ? debugLeds  :
//                  dbgSel3   ? aluLower   :
//                               ledsOut;

//endmodule




//`timescale 1ns/1ps
//module FpgaTop (
//    input        clk,
//    input        reset,
//    input  [15:0] switches,
//    input        btnMode,

//    output [15:0] leds,
//    output [3:0]  displayPower,
//    output [6:0]  segments
//);

//    // =========================================================
//    // Clock Divider - slows 100MHz to ~1Hz for visible output
//    // =========================================================
//    wire slowClk;
//    clkDivider u_divider (
//        .clkIn  (clk),
//        .reset  (reset),
//        .clkOut (slowClk)
//    );

//    // =========================================================
//    // Debounce mode button
//    // =========================================================
//    wire btnClean;
//    debouncer u_debounce (
//        .clk   (clk),
//        .pbin  (btnMode),
//        .pbout (btnClean)
//    );

//    // =========================================================
//    // Debug/Run mode toggle
//    // Reset starts in debug mode
//    // btnMode toggles between debug and run
//    // =========================================================
//    reg debugMode;
//    always @(posedge clk or posedge reset) begin
//        if (reset)
//            debugMode <= 1'b1;
//        else if (btnClean)
//            debugMode <= ~debugMode;
//    end

//    // =========================================================
//    // Processor clock - freeze when debug mode + sw[15] high
//    // =========================================================
//    wire processorClk = slowClk & ~(debugMode & switches[15]);

//    // =========================================================
//    // Processor sees 0 switches in debug mode
//    // =========================================================
//    wire [15:0] processorSwitches = debugMode ? 16'b0 : switches;

//    // =========================================================
//    // Debug signal wires
//    // =========================================================
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
//    wire        dbgMemToReg, dbgAluSrc, dbgBranch;
//    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
//    wire [31:0] dbgPC, dbgInstruction;
//    wire [15:0] ledsOut;

//    // =========================================================
//    // Top Level Processor
//    // =========================================================
//    TopLevelProcessor u_processor (
//        .clk           (processorClk),
//        .rst           (reset),
//        .sw_in         (processorSwitches),
//        .led_out       (ledsOut),
//        .dbgAluControl (dbgAluControl),
//        .dbgRegWrite   (dbgRegWrite),
//        .dbgMemRead    (dbgMemRead),
//        .dbgMemWrite   (dbgMemWrite),
//        .dbgMemToReg   (dbgMemToReg),
//        .dbgAluSrc     (dbgAluSrc),
//        .dbgBranch     (dbgBranch),
//        .dbgJump       (dbgJump),
//        .dbgJalr       (dbgJalr),
//        .dbgZero       (dbgZero),
//        .dbgLessThan   (dbgLessThan),
//        .dbgPC         (dbgPC),
//        .dbgInstruction(dbgInstruction)
//    );

//    // =========================================================
//    // Debug LED layout
//    // [15:12] aluControl
//    // [11]    regWrite
//    // [10]    memRead
//    // [9]     memWrite
//    // [8]     memToReg
//    // [7]     aluSrc
//    // [6]     branch
//    // [5]     jump
//    // [4]     jalr
//    // [3]     zero
//    // [2]     lessThan
//    // [1:0]   unused
//    // =========================================================
//    wire [15:0] debugLeds = {
//        dbgAluControl,
//        dbgRegWrite,
//        dbgMemRead,
//        dbgMemWrite,
//        dbgMemToReg,
//        dbgAluSrc,
//        dbgBranch,
//        dbgJump,
//        dbgJalr,
//        dbgZero,
//        dbgLessThan,
//        2'b00
//    };

//    // Run mode: show program LED output
//    // Debug mode: show control signals
//    assign leds = debugMode ? debugLeds : ledsOut;

//    // =========================================================
//    // Latch debug switch settings
//    // =========================================================
//    reg dbgSel0, dbgSel1, dbgSel2;
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            dbgSel0 <= 0;
//            dbgSel1 <= 0;
//            dbgSel2 <= 0;
//        end else if (debugMode) begin
//            dbgSel0 <= switches[0];
//            dbgSel1 <= switches[1];
//            dbgSel2 <= switches[2];
//        end
//    end

//    // =========================================================
//    // 7-Segment Display
//    // dbgSel0: 0=instruction, 1=PC
//    // dbgSel1: 0=lower 16 bits, 1=upper 16 bits
//    // dbgSel2: 0=instruction/PC, 1=LED value in BCD
//    // =========================================================
//    wire [31:0] instrOrPc = dbgSel0 ? dbgPC : dbgInstruction;

//    wire [3:0] bcdTh, bcdH, bcdT, bcdO;
//    BinaryToBCD u_bcd (
//        .bin      (ledsOut),
//        .thousands(bcdTh),
//        .hundreds (bcdH),
//        .tens     (bcdT),
//        .ones     (bcdO)
//    );

//    wire [15:0] ledsDecimal  = {bcdTh, bcdH, bcdT, bcdO};
//    wire [31:0] displaySource = dbgSel2 ? {16'b0, ledsDecimal} : instrOrPc;

//    SevenSegmentDriver u_sevenSeg (
//        .clk          (clk),
//        .reset        (reset),
//        .hexData      (dbgSel1 ? displaySource[31:16] : displaySource[15:0]),
//        .displayPower (displayPower),
//        .segments     (segments)
//    );

//endmodule