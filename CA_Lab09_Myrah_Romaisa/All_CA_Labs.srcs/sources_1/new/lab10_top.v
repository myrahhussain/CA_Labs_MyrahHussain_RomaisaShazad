`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2026 11:39:51 AM
// Design Name: 
// Module Name: lab10_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// ============================================================
// lab10_top.v
// Top-level module for Lab 10
// Instantiates: processor, instructionMemory, switches,
//               leds, debouncer
// ============================================================
`timescale 1ns/1ps

module lab10_top (
    input        clk,          // 10 MHz board clock
    input        rst_btn,      // raw reset push-button
    input  [15:0] sw,          // 16 slide switches
    output [15:0] led          // 16 LEDs
);

    // ----------------------------------------------------------
    // Debounced reset
    // ----------------------------------------------------------
    wire rst;
    debouncer u_dbnc (
        .clk   (clk),
        .pbin  (rst_btn),
        .pbout (rst)
    );

    // ----------------------------------------------------------
    // Processor ? memory-mapped bus signals
    // ----------------------------------------------------------
    wire [31:0] pc;           // program counter from processor
    wire [31:0] instruction;  // fetched instruction

    wire [31:0] memAddress_w; // 32-bit word address from processor
    wire [29:0] memAddress;   // lower 30 bits (word-addressed)
    wire [31:0] writeData;
    wire [31:0] readData;
    wire        writeEnable;
    wire        readEnable;

    assign memAddress = memAddress_w[31:2];

    // ----------------------------------------------------------
    // Instruction Memory
    // ----------------------------------------------------------
    instructionMemory u_imem (
        .instAddress (pc),          // byte-addressed PC
        .instruction (instruction)
    );

    // ----------------------------------------------------------
    // RISC-V Processor (single-cycle, from previous labs)
    // ----------------------------------------------------------
    riscv_processor u_cpu (
        .clk         (clk),
        .rst         (rst),
        .instruction (instruction),
        .pc          (pc),
        .readData    (readData),
        .writeData   (writeData),
        .memAddress  (memAddress_w),
        .writeEnable (writeEnable),
        .readEnable  (readEnable)
    );

    // ----------------------------------------------------------
    // Address decode: chip-select signals
    //   0xC0000000 >> 2 = 0x30000000 ? LEDs
    //   0xC0000004 >> 2 = 0x30000001 ? Switches
    //   0xC0000008 >> 2 = 0x30000002 ? Reset (read-only)
    // ----------------------------------------------------------
    wire cs_leds    = (memAddress == 30'h30000000);
    wire cs_sw      = (memAddress == 30'h30000001);
    wire cs_rst_reg = (memAddress == 30'h30000002);

    wire        leds_we   = writeEnable & cs_leds;
    wire        sw_re     = readEnable  & cs_sw;

    // ----------------------------------------------------------
    // LEDs peripheral
    // ----------------------------------------------------------
    wire [31:0] leds_rdata;   // not used (write-only)
    leds u_leds (
        .clk         (clk),
        .rst         (rst),
        .writeData   (writeData),
        .writeEnable (leds_we),
        .readEnable  (1'b0),
        .memAddress  (memAddress),
        .readData    (leds_rdata),
        .leds        (led)
    );

    // ----------------------------------------------------------
    // Switches peripheral
    // ----------------------------------------------------------
    wire [31:0] sw_rdata;
    switches u_sw (
        .clk         (clk),
        .rst         (rst),
        .btns        (16'b0),       // unused in this lab
        .writeData   (32'b0),
        .writeEnable (1'b0),
        .readEnable  (sw_re),
        .memAddress  (memAddress),
        .switches    (sw),
        .readData    (sw_rdata)
    );

    // ----------------------------------------------------------
    // Reset register (read-only, returns debounced rst on bit 0)
    // ----------------------------------------------------------
    wire [31:0] rst_rdata = {31'b0, rst};

    // ----------------------------------------------------------
    // Read data mux back to processor
    // ----------------------------------------------------------
    assign readData = cs_sw      ? sw_rdata  :
                      cs_rst_reg ? rst_rdata :
                                   32'b0;

endmodule