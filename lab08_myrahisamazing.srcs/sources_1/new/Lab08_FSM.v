`timescale 1ns / 1ps

module Lab08_FSM(
    input clk, rst, start,
    input [31:0] readData,        // Data from System Bus (Switches or Memory)
    output reg [31:0] address,
    output reg [31:0] writeData,
    output reg readEnable, writeEnable,
    output [2:0] current_state
);

    // State definitions
    localparam IDLE      = 3'b000;
    localparam READ_SW   = 3'b001; // First step: Always read the physical switches
    localparam WRITE_DM  = 3'b010;
    localparam READ_DM   = 3'b011;
    localparam SHOW_LEDS = 3'b100;

    reg [2:0] state, next_state;
    reg [31:0] buffer; // Internal register to hold data between states

    assign current_state = state;

    // State Transitions
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // Next State & Output Logic
    always @(*) begin
        // Defaults
        readEnable = 0;
        writeEnable = 0;
        address = 32'b0;
        writeData = 32'b0;
        next_state = state;

        case (state)
            IDLE: begin
                if (start) next_state = READ_SW;
            end

            // Step 1: Read Physical Switches to see the Mode, Address, and Data
            READ_SW: begin
                address = 32'd512; // Matches your Decoder 2'b10 case for switches
                readEnable = 1;
                // If sw[13]=0 -> Write Mode; If sw[13]=1 -> Read Mode
                if (readData[13] == 0) next_state = WRITE_DM;
                else next_state = READ_DM;
            end

            // Step 2 (Write Path): Store switch data sw[7:0] into Memory
            WRITE_DM: begin
                address = {24'b0, 3'b0, buffer[12:8]}; // Memory offset from switches
                writeData = {24'b0, buffer[7:0]};     // Immediate data from switches
                writeEnable = 1;
                next_state = SHOW_LEDS;
            end

            // Step 2 (Read Path): Get data from Memory offset sw[12:8]
            READ_DM: begin
                address = {24'b0, 3'b0, buffer[12:8]}; // Memory offset from switches
                readEnable = 1;
                next_state = SHOW_LEDS;
            end

            // Step 3: Write the result to the LEDs
            SHOW_LEDS: begin
                address = 32'd256; // Matches  Decoder 2'b01 case for LEDs
                // Use the switch data if we wrote, or memory data if we read
                writeData = (buffer[13] == 0) ? {24'b0, buffer[7:0]} : readData;
                writeEnable = 1;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Buffer Logic: Capture data from the bus at the end of each read state
  always @(posedge clk) begin
        if (rst) buffer <= 32'b0;
        // Capture data when the FSM is asking for a read
        else if (state == READ_SW || state == READ_DM) buffer <= readData; 
    end
endmodule
//`timescale 1ns / 1ps

//module Lab08_FSM(
//    input clk, rst, start,
//    input [31:0] readData,
//    output reg [31:0] address,
//    output reg [31:0] writeData,
//    output reg readEnable, writeEnable,
//    output [2:0] current_state
//);

//    // State definitions
//    localparam IDLE      = 3'b000;
//    localparam WRITE_DM  = 3'b001;
//    localparam READ_DM   = 3'b010;
//    localparam SHOW_LEDS = 3'b011;

//    reg [2:0] state, next_state;
//    reg [31:0] buffer;

//    assign current_state = state;

//    // State Transitions
//    always @(posedge clk) begin
//        if (rst) state <= IDLE;
//        else state <= next_state;
//    end

//    // Next State & Output Logic
//    always @(*) begin
//        // Defaults
//        readEnable = 0;
//        writeEnable = 0;
//        address = 32'b0;
//        writeData = 32'b0;
//        next_state = state;

//        case (state)
//            IDLE: begin
//                if (start) begin
//                    // Check switch[13]: 0 = Write to RAM, 1 = Read from RAM
//                    if (readData[13] == 0) next_state = WRITE_DM;
//                    else next_state = READ_DM;
//                end
//            end

//            WRITE_DM: begin
//                address = {24'b0, 3'b0, readData[12:8]}; // 5-bit Addr from switches
//                writeData = {24'b0, readData[7:0]};     // 8-bit Data from switches
//                writeEnable = 1;
//                next_state = SHOW_LEDS;
//            end

//            READ_DM: begin
//                address = {24'b0, 3'b0, readData[12:8]};
//                readEnable = 1;
//                next_state = SHOW_LEDS;
//            end

//            SHOW_LEDS: begin
//                address = 32'd512; // Your LED address
//                // If we wrote, show the input. If we read, show the RAM output.
//                writeData = buffer; 
//                writeEnable = 1;
//                next_state = IDLE;
//            end
//        endcase
//    end

//    // Buffer to hold data between states
//    always @(posedge clk) begin
//        if (state == READ_DM) buffer <= readData;
//        else if (state == WRITE_DM) buffer <= {24'b0, readData[7:0]};
//    end

//endmodule


//`timescale 1ns / 1ps

//module Lab08_FSM (
//    input clk,
//    input rst,
//    input start,              // Cleaned pushbutton to start the sequence
//    input [31:0] readData,    // Data coming back from the Address Decoder
//    output reg [31:0] address,
//    output reg [31:0] writeData,
//    output reg readEnable,
//    output reg writeEnable,
//    output [2:0] current_state // For debugging on LEDs
//);

//    // State Encoding
//    localparam IDLE           = 3'b000,
//               READ_SWITCHES  = 3'b001,
//               WRITE_DATAMEM  = 3'b010,
//               READ_DATAMEM   = 3'b011,
//               WRITE_LED      = 3'b100;

//    reg [2:0] state, next_state;
//    reg [31:0] buffer; // Internal register to hold data during the move

//    // State Register
//    always @(posedge clk or posedge rst) begin
//        if (rst) 
//            state <= IDLE;
//        else 
//            state <= next_state;
//    end

//    // Next State Logic
//    always @(*) begin
//        next_state = state;
//        case (state)
//            IDLE:          if (start) next_state = READ_SWITCHES;
//            READ_SWITCHES: next_state = WRITE_DATAMEM;
//            WRITE_DATAMEM: next_state = READ_DATAMEM;
//            READ_DATAMEM:  next_state = WRITE_LED;
//            WRITE_LED:     next_state = IDLE;
//            default:       next_state = IDLE;
//        endcase
//    end

//    // Output Logic (Control Signals)
//    always @(*) begin
//        address = 0;
//        writeData = 0;
//        readEnable = 0;
//        writeEnable = 0;

//        case (state)
//            READ_SWITCHES: begin
//                address = 32'd768; // Switch range (Address Decoder case 2'b10)
//                readEnable = 1;
//            end
//            WRITE_DATAMEM: begin
//                address = 32'd10;  // Slot 10 in RAM (Address Decoder case 2'b00)
//                writeData = buffer;
//                writeEnable = 1;
//            end
//            READ_DATAMEM: begin
//                address = 32'd10;  // Read back from Slot 10
//                readEnable = 1;
//            end
//            WRITE_LED: begin
//                address = 32'd512; // LED range (Address Decoder case 2'b01)
//                writeData = buffer;
//                writeEnable = 1;
//            end
//        endcase
//    end

//    // Buffer to capture read data from the system bus
//    always @(posedge clk) begin
//        if (readEnable) 
//            buffer <= readData;
//    end

//    assign current_state = state;

//endmodule