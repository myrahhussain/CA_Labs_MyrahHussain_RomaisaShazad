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
    wire [15:0] internal_led_bus; // Wire to capture output from led_unit

    // 1. Address Decoder: Takes full 32-bit bus, looks at [9:8]
    AddressDecoder decoder (
        .address(address),
        .readEnable(readEnable),
        .writeEnable(writeEnable),
        .memWrite(memWrite),
        .ledWrite(ledWrite),
        .switchRead(switchRead)
    );

    // 2. Data Memory: Uses exactly 9 bits to access all 512 locations
    DataMemory dm (
        .clk(clk),
        .rst(rst),
        .memWrite(memWrite),
        .address(address[8:0]), 
        .writeData(writeData),
        .readData(memReadData)
    );

    // 3. LED Module: Reusing Lab 5 Template
    leds led_unit (
        .clk(clk), 
        .rst(rst),
        .btns(16'b0),           
        .writeData(writeData),
        .writeEnable(ledWrite), 
        .readEnable(1'b0), 
        .memAddress(30'b0),     
        .switches(switches_in), 
        .readData(),            
        .leds(internal_led_bus) // Connect the internal register to our wire
    );
    
    // Drive the physical output pins with the data captured in led_unit
    assign leds_out = internal_led_bus;

    // 4. Switch Module: Reusing Lab 5 Template
    switches sw_unit (
        .clk(clk), 
        .rst(rst),
        .writeData(32'b0),
        .writeEnable(1'b0),
        .readEnable(switchRead),
        .memAddress(30'b0),
        .readData(swReadData),
        .leds(switches_in)      // Maps the physical switches to the module input
    );

    // 5. Final Read Data Multiplexer
    // Decides whether the CPU reads from RAM or from the Switches
    assign readData = (address[9:8] == 2'b00) ? memReadData :
                      (address[9:8] == 2'b10) ? swReadData : 32'b0;

endmodule

//`timescale 1ns / 1ps

//module AddressDecoderTop (
//    input clk, rst,
//    input [31:0] address,
//    input readEnable, writeEnable,
//    input [31:0] writeData,
//    input [15:0] switches_in, // From physical FPGA pins
//    output [31:0] readData,   // Back to CPU
//    output [15:0] leds_out    // To physical FPGA LEDs
//);
//    // Internal Wires
//    wire memWrite, ledWrite, switchRead;
//    wire [31:0] memReadData, swReadData;

//    // 1. Address Decoder
//    AddressDecoder decoder (
//        .address(address),
//        .readEnable(readEnable),
//        .writeEnable(writeEnable),
//        .memWrite(memWrite),
//        .ledWrite(ledWrite),
//        .switchRead(switchRead)
//    );

//    // 2. Data Memory
//    DataMemory dm (
//        .clk(clk),
//        .memWrite(memWrite),
//        .addr(address[8:0]),
//        .wData(writeData),
//        .rData(memReadData)
//    );

//    // 3. LED Module (Reusing Lab 5 Template)
//    leds led_unit (
//        .clk(clk), 
//        .rst(rst),
//        .btns(16'b0),          // Port required by Lab 5 template
//        .writeData(writeData),
//        .writeEnable(ledWrite), 
//        .readEnable(1'b0), 
//        .memAddress(30'b0),    // Port required by Lab 5 template
//        .switches(switches_in), // Port required by Lab 5 template
//        .readData()             // Output from LED module
//    );
    
//    // Assigning the internal LED signals to the Top output
//    // Note: You may need to modify the 'leds' module to drive this properly
//    assign leds_out = switches_in; // Temporary mapping for synthesis

//    // 4. Switch Module (Reusing Lab 5 Template)
//    switches sw_unit (
//        .clk(clk), 
//        .rst(rst),
//        .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(switchRead),
//        .memAddress(30'b0),
//        .readData(swReadData),
//        .leds()                 // Output reg from switch module template
//    );

//    // 5. Final Read Data Multiplexer
//    // Selects which data the CPU actually sees
//    assign readData = (address[9:8] == 2'b00) ? memReadData :
//                      (address[9:8] == 2'b10) ? swReadData : 32'b0;

//endmodule