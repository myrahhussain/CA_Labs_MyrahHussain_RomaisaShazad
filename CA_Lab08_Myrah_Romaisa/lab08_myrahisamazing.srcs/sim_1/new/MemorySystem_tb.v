`timescale 1ns / 1ps

// Verifies data memory, LED, and switch operations including reset behaviour
// and cross-talk checks (writes to one device should not affect others)
module MemorySystem_tb;
    reg clk;
    reg rst;
    reg [31:0] address;
    reg readEnable;
    reg writeEnable;
    reg [31:0] writeData;
    reg [15:0] switches;
    wire [31:0] readData;
    wire [15:0] leds;

    // 10ns clock period (100 MHz)
    always #5 clk = ~clk;

    // Device under test
    AddressDecoderTOP dut (
        .clk(clk),
        .rst(rst),
        .address(address),
        .readEnable(readEnable),
        .writeEnable(writeEnable),
        .writeData(writeData),
        .switches_in(switches),
        .readData(readData),
        .leds_out(leds)
    );

    initial begin
        // Initialise all signals and hold reset high
        clk = 0; rst = 1;
        address = 0; readEnable = 0; writeEnable = 0;
        writeData = 0; switches = 0;

        // Release reset
        #10 rst = 0;

        // Test 1: Write 0xDEADBEEF to data memory address 0x00
        #3  address = 32'h00000000; writeData = 32'hDEADBEEF; writeEnable = 1;
        #10 writeEnable = 0;

        // Test 4a: Write 0xABCD to LED interface
        #3  address = 32'h00000100; writeData = 32'h0000ABCD; writeEnable = 1;
        #10 writeEnable = 0;

        // Test 5a: Read switches with value 0xA5A5
        #3  address = 32'h00000200; switches = 16'hA5A5; readEnable = 1;
        #10 readEnable = 0;

        // Test 5b: Read switches with new value 0x1234 - confirms live input captured
        #3  address = 32'h00000200; switches = 16'h1234; readEnable = 1;
        #10 readEnable = 0;

        // Test 6: Read data memory - should still be 0xDEADBEEF (LED write must not affect DM)
        #3  address = 32'h00000000; readEnable = 1;
        #10 readEnable = 0;

        // Test 7: Write to a different DM address - LEDs must remain unchanged
        #3  address = 32'h00000010; writeData = 32'hFFFFFFFF; writeEnable = 1;
        #10 writeEnable = 0;

        // Test 8: Assert reset - clears memory and LEDs
        #3  rst = 1;
        #10 rst = 0;

        // Test 9: Write to DM while reset is high - write must be blocked
        #3  rst = 1; address = 32'h00000010; writeData = 32'hFFFFFFFF; writeEnable = 1;
        #10 rst = 0; writeEnable = 0;

        // Test 10: Write to LEDs while reset is high - write must be blocked
        #3  rst = 1; address = 32'h00000100; writeData = 32'hFFFFFFFF; writeEnable = 1;
        #10 rst = 0; writeEnable = 0;

        #50 $finish;
    end

    // Print signal values every time any monitored signal changes
    initial begin
        $monitor("Time=%0t rst=%b addr=%h we=%b re=%b wdata=%h rdata=%h leds=%h",
                 $time, rst, address, writeEnable, readEnable, writeData, readData, leds);
    end
endmodule