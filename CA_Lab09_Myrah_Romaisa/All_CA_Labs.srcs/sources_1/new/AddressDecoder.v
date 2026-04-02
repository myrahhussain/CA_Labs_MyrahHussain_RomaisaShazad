`timescale 1ns / 1ps

// Address Decoder Module
// Decodes address[9:8] to enable exactly one device at a time.
// Prevents bus contention by ensuring only one enable signal is high per access.
module AddressDecoder(
    input [1:0] address,      // address[9:8] - selects the target device
    input readEnable,         // From CPU - read request
    input writeEnable,        // From CPU - write request
    output dataMemWrite,      // Enables data memory write  (address = 00)
    output dataMemRead,       // Enables data memory read   (address = 00)
    output LEDWrite,          // Enables LED write          (address = 01)
    output switchReadEnable   // Enables switch read        (address = 10)
);
    // Each output is only active when the correct device is selected
    // AND the corresponding read/write enable from the CPU is asserted
    assign dataMemWrite     = (address == 2'b00) ? writeEnable : 1'b0;
    assign dataMemRead      = (address == 2'b00) ? readEnable  : 1'b0;
    assign LEDWrite         = (address == 2'b01) ? writeEnable : 1'b0;
    assign switchReadEnable = (address == 2'b10) ? readEnable  : 1'b0;
    
endmodule