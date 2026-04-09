`timescale 1ns / 1ps

module AddressDecoder (
    input [31:0] address,
    input readEnable,
    input writeEnable,
    output reg memWrite,    // To Data Memory
    output reg ledWrite,    // To LED Module
    output reg switchRead   // To Switch Module
);
    always @(*) begin
        // Default: everything is off
        memWrite = 0; ledWrite = 0; switchRead = 0;
        
        case (address[9:8])
            2'b00: memWrite = writeEnable;   // Address 0-511
            2'b01: ledWrite = writeEnable;   // Address 512-767
            2'b10: switchRead = readEnable;  // Address 768-1023
            default: ; 
        endcase
    end
endmodule