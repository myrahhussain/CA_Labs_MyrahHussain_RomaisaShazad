`timescale 1ns / 1ps

module Lab08_top (
    input clk,
    input rst,                // Map to a pushbutton
    input start,              // Map to a pushbutton (e.g., btnC)
    input [15:0] switches_in, // Map to switches [15:0]
    output [15:0] leds_out,   // Map to LEDs [15:0]
    output [2:0] state_debug  // Map to 3 specific LEDs to see the state
);

    // Internal Wires for the Bus
    wire [31:0] fsm_addr;
    wire [31:0] fsm_writeData;
    wire [31:0] system_readData;
    wire fsm_readEn;
    wire fsm_writeEn;
    wire clean_start;

    // 1. Instantiate Debouncer to clean the start button
    debouncer start_filter (
        .clk(clk),
        .pbin(start),
        .pbout(clean_start)
    );

    // 2. Instantiate the FSM (The Controller)
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

    // 3. Instantiate the Memory System (The Infrastructure)
    AddressDecoderTop memory_system (
        .clk(clk),
        .rst(rst),
        .address(fsm_addr),
        .readEnable(fsm_readEn),
        .writeEnable(fsm_writeEn),
        .writeData(fsm_writeData),
        .switches_in(switches_in),
        .readData(system_readData),
        .leds_out(leds_out)
    );

endmodule