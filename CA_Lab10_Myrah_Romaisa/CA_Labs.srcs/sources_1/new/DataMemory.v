`timescale 1ns / 1ps

module DataMemory(
    input clk, 
    input rst, 
    input memWrite,      // Write Enable from Decoder
    input [8:0] address, // 9-bit address for 512 locations
    input [31:0] writeData,
    output [31:0] readData
);
    // Create the 512 x 32-bit memory array
    reg [31:0] memory [511:0];
    integer i;

    // Synchronous Write Logic
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<512; i=i+1)
                memory[i] <= 32'b0;
        end
        else if (memWrite) begin
            memory[address] <= writeData;
        end
    end

    // Asynchronous Read Logic
    assign readData = memory[address];

endmodule

//`timescale 1ns / 1ps

//module DataMemory (
//    input clk,
//    input memWrite,      // Enabled by Address Decoder
//    input [8:0] addr,    // address[8:0]
//    input [31:0] wData,  // writeData
//    output [31:0] rData  // readData
//);
//    reg [31:0] mem [0:511];

//    // Synchronous Write
//    always @(posedge clk) begin
//        if (memWrite)
//            mem[addr] <= wData;
//    end

//    // Asynchronous Read
//    assign rData = mem[addr];
//endmodule