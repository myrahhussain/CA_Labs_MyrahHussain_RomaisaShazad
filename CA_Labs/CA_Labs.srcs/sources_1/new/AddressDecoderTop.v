`timescale 1ns / 1ps

module AddressDecoderTop (
    input clk, rst,
    input [31:0] address,
    input readEnable, writeEnable,
    input [31:0] writeData,
    input [15:0] switches_in, // From physical FPGA pins
    output [31:0] readData,   // Back to CPU
    output [15:0] leds_out    // To physical FPGA LEDs
);
    // Internal Wires
    wire memWrite, ledWrite, switchRead;
    wire [31:0] memReadData, swReadData;

    // 1. Address Decoder
    AddressDecoder decoder (
        .address(address),
        .readEnable(readEnable),
        .writeEnable(writeEnable),
        .memWrite(memWrite),
        .ledWrite(ledWrite),
        .switchRead(switchRead)
    );

    // 2. Data Memory
    DataMemory dm (
        .clk(clk),
        .memWrite(memWrite),
        .addr(address[8:0]),
        .wData(writeData),
        .rData(memReadData)
    );

    // 3. LED Module (Reusing Lab 5 Template)
    leds led_unit (
        .clk(clk), 
        .rst(rst),
        .btns(16'b0),          // Port required by Lab 5 template
        .writeData(writeData),
        .writeEnable(ledWrite), 
        .readEnable(1'b0), 
        .memAddress(30'b0),    // Port required by Lab 5 template
        .switches(switches_in), // Port required by Lab 5 template
        .readData()             // Output from LED module
    );
    
    // Assigning the internal LED signals to the Top output
    // Note: You may need to modify the 'leds' module to drive this properly
    assign leds_out = switches_in; // Temporary mapping for synthesis

    // 4. Switch Module (Reusing Lab 5 Template)
    switches sw_unit (
        .clk(clk), 
        .rst(rst),
        .writeData(32'b0),
        .writeEnable(1'b0),
        .readEnable(switchRead),
        .memAddress(30'b0),
        .readData(swReadData),
        .leds()                 // Output reg from switch module template
    );

    // 5. Final Read Data Multiplexer
    // Selects which data the CPU actually sees
    assign readData = (address[9:8] == 2'b00) ? memReadData :
                      (address[9:8] == 2'b10) ? swReadData : 32'b0;

endmodule