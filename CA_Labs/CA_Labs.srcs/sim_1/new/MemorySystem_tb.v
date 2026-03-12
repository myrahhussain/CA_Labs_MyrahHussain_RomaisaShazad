`timescale 1ns / 1ps

module MemorySystem_tb();
    reg clk, rst, readEnable, writeEnable;
    reg [31:0] address, writeData;
    reg [15:0] switches_in;
    wire [31:0] readData;
    wire [15:0] leds_out;

    AddressDecoderTop uut (
    .clk(clk),
    .rst(rst),
    .address(address),
    .readEnable(readEnable),
    .writeEnable(writeEnable),
    .writeData(writeData),
    .switches_in(switches_in),
    .readData(readData),
    .leds_out(leds_out)
);

    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    initial begin
        rst = 1; #10 rst = 0;
        
        // Test 1: Write to Data Memory (Addr 10)
        address = 32'd10; writeData = 32'hAAAA_BBBB; writeEnable = 1; #10;
        writeEnable = 0; #10;
        
        // Test 2: Read from Data Memory (Addr 10)
        readEnable = 1; #10;
        readEnable = 0; #10;

        // Test 3: Write to LEDs (Addr 520)
        address = 32'd520; writeData = 32'h0000_FFFF; writeEnable = 1; #10;
        writeEnable = 0; #10;

        // Test 4: Read from Switches (Addr 800)
        switches_in = 16'h1234;
        address = 32'd800; readEnable = 1; #10;
        readEnable = 0; #10;

        $stop;
    end
endmodule

