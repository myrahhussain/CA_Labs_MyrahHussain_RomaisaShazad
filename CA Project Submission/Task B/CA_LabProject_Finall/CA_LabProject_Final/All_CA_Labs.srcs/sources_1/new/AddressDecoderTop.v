`timescale 1ns / 1ps

// Address Decoder Top Module
// Connects the CPU to all three devices: Data Memory, LEDs, and Switches.
// Instantiates the address decoder and routes data to the correct device.
module AddressDecoderTOP(
    input clk,
    input rst,
    input [31:0] address,       // full 32-bit CPU address
    input readEnable,           // CPU wants to read
    input writeEnable,          // CPU wants to write
    input [31:0] writeData,     // data from CPU to write
    input [15:0] switches_in,   // physical switch inputs
    output [31:0] readData,     // data returned to CPU
    output [15:0] leds_out      // drives physical LEDs
);
    // Internal enable signals from decoder
    wire dataMemWrite, dataMemRead, LEDWrite, switchReadEnable;
    // Read data wires from each device
    wire [31:0] dm_readData, sw_readData;

    // Decode address[9:8] to generate device enable signals
    AddressDecoder ad (
        .address(address[9:8]),
        .readEnable(readEnable),
        .writeEnable(writeEnable),
        .dataMemWrite(dataMemWrite),
        .dataMemRead(dataMemRead),
        .LEDWrite(LEDWrite),
        .switchReadEnable(switchReadEnable)
    );

    // Data Memory - uses lower 8 bits as local address
    DataMemory dataMem (
        .clk(clk),
        .rst(rst),
        .address(address[7:0]),
        .memWrite(dataMemWrite),
        .writeData(writeData),
        .readData(dm_readData)
    );

    // LED interface - write only, readEnable tied low
    leds led_inst (
        .clk(clk),
        .rst(rst),
        .writeData(writeData),
        .writeEnable(LEDWrite),
        .readEnable(1'b0),              // LEDs are write-only in this system
        .memAddress(address[31:2]),     // pass upper bits as memAddress [29:0]
        // readData output unused
        .leds(leds_out)
    );

    // Switch interface - read only, write signals tied low
    switches sw_inst (
        .clk(clk),
        .rst(rst),
        .btns(16'b0),                   // no physical buttons used here
        .writeData(32'b0),              // switches are read-only
        .writeEnable(1'b0),
        .readEnable(switchReadEnable),
        .memAddress(address[31:2]),
        .switches(switches_in),
        .readData(sw_readData)
    );

    // Return data from the selected device back to CPU
    // Only data memory and switches can be read
    assign readData = (address[9:8] == 2'b00) ? dm_readData :
                      (address[9:8] == 2'b10) ? sw_readData :
                      32'b0;
endmodule