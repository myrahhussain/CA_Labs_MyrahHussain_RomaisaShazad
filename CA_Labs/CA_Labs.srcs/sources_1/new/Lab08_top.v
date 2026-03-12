`timescale 1ns / 1ps

`timescale 1ns / 1ps

module Lab08_top (
    input clk,
    input rst,
    input start,              // Pushbutton to trigger the FSM sequence
    input [15:0] switches_in, // Physical FPGA switches
    output [15:0] leds_out,   // Physical FPGA LEDs
    output [2:0] state_debug  // Connected to LEDs to see FSM state
);

    // Internal Wires connecting the FSM to the Decoder
    wire [31:0] fsm_addr;
    wire [31:0] fsm_writeData;
    wire [31:0] system_readData;
    wire fsm_readEn;
    wire fsm_writeEn;

    // 1. Instantiate the FSM (The Controller)
    // Note: Using your name Lab08_FSM here
    Lab08_FSM controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .readData(system_readData),
        .address(fsm_addr),
        .writeData(fsm_writeData),
        .readEnable(fsm_readEn),
        .writeEnable(fsm_writeEn),
        .current_state(state_debug)
    );

    // 2. Instantiate the Memory System (The Infrastructure)
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