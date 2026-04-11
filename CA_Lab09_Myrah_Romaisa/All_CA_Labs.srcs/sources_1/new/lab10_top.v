`timescale 1ns/1ps

module lab10_top (
    input  wire        clk,
    input  wire        rst_btn,
    input  wire [15:0] sw,
    output wire [15:0] led
);

    // Debouncer only matters on FPGA.
    // In simulation, pbout stays X for 1M cycles.
    // Solution: OR the raw button with debounced output
    // so rst is asserted immediately when button pressed.
    wire rst_debounced;
    debouncer u_dbnc (
        .clk   (clk),
        .pbin  (rst_btn),
        .pbout (rst_debounced)
    );

    // Use raw rst_btn directly - debouncer handles glitches on FPGA
    // but for simulation correctness we need immediate response
    wire rst = rst_btn | rst_debounced;

    // ----------------------------------------------------------
    // Processor <-> instruction memory
    // ----------------------------------------------------------
    wire [31:0] pc;
    wire [31:0] instruction;

    instructionMemory u_imem (
        .instAddress (pc),
        .instruction (instruction)
    );

    // ----------------------------------------------------------
    // Processor <-> data memory bus
    // ----------------------------------------------------------
    wire [31:0] memAddress;
    wire [31:0] writeData;
    wire [31:0] readData;
    wire        writeEnable;
    wire        readEnable;

    riscv_processor u_cpu (
        .clk         (clk),
        .rst         (rst),
        .instruction (instruction),
        .pc          (pc),
        .readData    (readData),
        .writeData   (writeData),
        .memAddress  (memAddress),
        .writeEnable (writeEnable),
        .readEnable  (readEnable)
    );

    // ----------------------------------------------------------
    // Address decode
    // ----------------------------------------------------------
    wire cs_leds = (memAddress == 32'hC0000000);
    wire cs_sw   = (memAddress == 32'hC0000004);
    wire cs_rst  = (memAddress == 32'hC0000008);

    // ----------------------------------------------------------
    // LEDs peripheral
    // ----------------------------------------------------------
    wire [31:0] leds_rdata;
    leds u_leds (
        .clk         (clk),
        .rst         (rst),
        .writeData   (writeData),
        .writeEnable (writeEnable & cs_leds),
        .readEnable  (1'b0),
        .memAddress  (30'b0),
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
        .btns        (16'b0),
        .writeData   (32'b0),
        .writeEnable (1'b0),
        .readEnable  (readEnable & cs_sw),
        .memAddress  (30'b0),
        .switches    (sw),
        .readData    (sw_rdata)
    );

    // ----------------------------------------------------------
    // Reset register
    // ----------------------------------------------------------
    wire [31:0] rst_rdata = {31'b0, rst};

    // ----------------------------------------------------------
    // Read data mux
    // ----------------------------------------------------------
    assign readData = cs_sw  ? sw_rdata  :
                      cs_rst ? rst_rdata :
                               32'b0;

endmodule