`timescale 1ns / 1ps

module Lab08_top (
    input clk,
    input rst,                
    input start,              
    input [15:0] switches_in, // Physical FPGA Switch pins
    output [15:0] leds_out,   // Physical FPGA LED pins
    output [2:0] state_debug  
);

    // Internal Wires for the Bus
    wire [31:0] fsm_addr;
    wire [31:0] fsm_writeData;
    wire [31:0] system_readData;
    wire fsm_readEn;
    wire fsm_writeEn;
    wire clean_start;

    // 1. Instantiate Debouncer
    debouncer start_filter (
        .clk(clk),
        .pbin(start),
        .pbout(clean_start)
    );

    // 2. Instantiate the FSM
    Lab08_FSM controller (
        .clk(clk),
        .rst(rst),
        .start(clean_start),
        .readData(system_readData),
        .address(fsm_addr),
        .writeData(fsm_writeData),
        .readEnable(fsm_readEn),
        .writeEnable(fsm_writeEn),
        .current_state(state_debug)
    );

    // 3. Instantiate the Memory System (Updated with new port names)
    addressDecoderTop memory_system (
        .clk(clk),
        .rst(rst),
        .address(fsm_addr),
        .readEnable(fsm_readEn),
        .writeEnable(fsm_writeEn),
        .writeData(fsm_writeData),
        .switches(switches_in), // Port name updated to 'switches'
        .readData(system_readData),
        .leds(leds_out)        // Port name updated to 'leds'
    );

endmodule