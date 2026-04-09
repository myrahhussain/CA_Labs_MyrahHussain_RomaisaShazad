`timescale 1ns / 1ps

module Lab08_FSM (
    input clk,
    input rst,
    input start,              // Cleaned pushbutton to start the sequence
    input [31:0] readData,    // Data coming back from the Address Decoder
    output reg [31:0] address,
    output reg [31:0] writeData,
    output reg readEnable,
    output reg writeEnable,
    output [2:0] current_state // For debugging on LEDs
);

    // State Encoding
    localparam IDLE           = 3'b000,
               READ_SWITCHES  = 3'b001,
               WRITE_DATAMEM  = 3'b010,
               READ_DATAMEM   = 3'b011,
               WRITE_LED      = 3'b100;

    reg [2:0] state, next_state;
    reg [31:0] buffer; // Internal register to hold data during the move

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) 
            state <= IDLE;
        else 
            state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:          if (start) next_state = READ_SWITCHES;
            READ_SWITCHES: next_state = WRITE_DATAMEM;
            WRITE_DATAMEM: next_state = READ_DATAMEM;
            READ_DATAMEM:  next_state = WRITE_LED;
            WRITE_LED:     next_state = IDLE;
            default:       next_state = IDLE;
        endcase
    end

    // Output Logic (Control Signals)
    always @(*) begin
        address = 0;
        writeData = 0;
        readEnable = 0;
        writeEnable = 0;

        case (state)
            READ_SWITCHES: begin
                address = 32'd768; // Switch range (Address Decoder case 2'b10)
                readEnable = 1;
            end
            WRITE_DATAMEM: begin
                address = 32'd10;  // Slot 10 in RAM (Address Decoder case 2'b00)
                writeData = buffer;
                writeEnable = 1;
            end
            READ_DATAMEM: begin
                address = 32'd10;  // Read back from Slot 10
                readEnable = 1;
            end
            WRITE_LED: begin
                address = 32'd512; // LED range (Address Decoder case 2'b01)
                writeData = buffer;
                writeEnable = 1;
            end
        endcase
    end

    // Buffer to capture read data from the system bus
    always @(posedge clk) begin
        if (readEnable) 
            buffer <= readData;
    end

    assign current_state = state;

endmodule