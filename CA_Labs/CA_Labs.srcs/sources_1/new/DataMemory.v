`timescale 1ns / 1ps

module DataMemory (
    input clk,
    input memWrite,      // Enabled by Address Decoder
    input [8:0] addr,    // address[8:0]
    input [31:0] wData,  // writeData
    output [31:0] rData  // readData
);
    reg [31:0] mem [0:511];

    // Synchronous Write
    always @(posedge clk) begin
        if (memWrite)
            mem[addr] <= wData;
    end

    // Asynchronous Read
    assign rData = mem[addr];
endmodule