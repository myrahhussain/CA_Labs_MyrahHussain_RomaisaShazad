`timescale 1ns / 1ps

// Data Memory Module
// Implements a 512-location x 32-bit synchronous write, asynchronous read memory.
module DataMemory(
    input clk,          // System clock
    input rst,          // Synchronous reset - clears all memory to 0
    input [7:0] address, // 8-bit address - selects one of 512 locations
    input memWrite,     // Write enable - high to store writeData into memory
    input [31:0] writeData,  // 32-bit data to write
    output [31:0] readData   // 32-bit data read out (asynchronous)
);

    // 512 x 32-bit memory array
    reg [31:0] memory [0:511];
    integer i;
    
    // Synchronous write and reset
    // On reset: all 512 locations cleared to 0
    // On memWrite: store writeData at the given address
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 512; i = i + 1)
                memory[i] <= 32'b0;
        end else if (memWrite) begin
            memory[address] <= writeData;
        end
    end
    
    // Asynchronous read - always outputs current value at address,
    // no clock edge required
    assign readData = memory[address];
    
endmodule