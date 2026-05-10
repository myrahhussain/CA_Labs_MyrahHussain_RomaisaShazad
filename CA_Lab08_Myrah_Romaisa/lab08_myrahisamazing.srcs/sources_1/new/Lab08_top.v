`timescale 1ns / 1ps


// Implements an FSM that lets the user write/read data memory and display
// results on LEDs using physical switches as input
module top_lab8(
    input clk,              
    input btn_reset,        // active-high reset button
    input [15:0] sw,        // switch inputs 
    output [15:0] led       // LED outputs
);
    // Switch layout: [Trigger[15] | Mode[13] | Mem Address[12:8] | Imm[7:0]]
    // sw[15] = trigger (toggle to start), sw[13] = mode (0=write, 1=read)
    // sw[12:8] = memory address, sw[7:0] = data to write

    // Debounce reset button and sw[15] trigger to avoid glitches
    wire clean_reset;
    debouncer db(
        .clk(clk),
        .pbin(btn_reset),
        .pbout(clean_reset)
    );
    wire clean_sw15;
    debouncer db1(
        .clk(clk),
        .pbin(sw[15]),
        .pbout(clean_sw15)
    );

    // Edge detector on sw[15] - generates a single-cycle pulse on each toggle
    reg sw15_delay;
    wire trigger_pulse;
    always @(posedge clk) begin
        if (clean_reset)
            sw15_delay <= 1'b0;
        else
            sw15_delay <= clean_sw15;
    end
    assign trigger_pulse = clean_sw15 & ~sw15_delay;

    // Memory system signals
    reg [31:0] address;
    reg readEnable, writeEnable;
    reg [31:0] writeData;
    wire [31:0] readData;

    // Instantiate memory system - note updated port name switches_in / leds_out
    AddressDecoderTOP mem_sys(
        .clk(clk),
        .rst(clean_reset),
        .address(address),
        .readEnable(readEnable),
        .writeEnable(writeEnable),
        .writeData(writeData),
        .switches_in(sw),
        .readData(readData),
        .leds_out(led)
    );

    // FSM state encoding
    localparam IDLE      = 3'b000;  // wait for trigger
    localparam WRITE_DM  = 3'b001;  // write sw[7:0] to data memory
    localparam READ_DM   = 3'b010;  // assert read request
    localparam WAIT_READ = 3'b011;  // extra cycle for readData to settle
    localparam SHOW_LEDS = 3'b100;  // write result to LED interface

    reg [2:0] state, next_state;

    // State register - advances on every clock edge
    always @(posedge clk) begin
        if (clean_reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Capture readData once it has settled (one cycle after read is asserted)
    reg [31:0] captured_read;
    always @(posedge clk) begin
        if (clean_reset)
            captured_read <= 32'b0;
        else if (state == WAIT_READ)
            captured_read <= readData;
    end

    // Combinational next-state and output logic
    always @(*) begin
        next_state  = state;
        address     = 32'b0;
        readEnable  = 0;
        writeEnable = 0;
        writeData   = 32'b0;

        case (state)
            IDLE: begin
                // Wait for trigger - sw[13] selects write or read mode
                if (trigger_pulse)
                    next_state = (sw[13] == 0) ? WRITE_DM : READ_DM;
            end

            WRITE_DM: begin
                // Write sw[7:0] to data memory at address sw[12:8]
                address     = {22'b0, 2'b00, 3'b0, sw[12:8]};
                writeData   = {24'b0, sw[7:0]};
                writeEnable = 1;
                next_state  = SHOW_LEDS;
            end

            READ_DM: begin
                // Assert address and readEnable so memory latches the read
                address    = {22'b0, 2'b00, 3'b0, sw[12:8]};
                readEnable = 1;
                next_state = WAIT_READ;
            end

            WAIT_READ: begin
                // Hold address/readEnable one more cycle so readData is valid
                address    = {22'b0, 2'b00, 3'b0, sw[12:8]};
                readEnable = 1;
                next_state = SHOW_LEDS;
            end

            SHOW_LEDS: begin
                // Write result to LED interface (address[9:8]=01 selects LEDs)
                // Write mode: show sw[7:0] - Read mode: show captured memory value
                address     = 32'h00000100;
                writeData   = (sw[13] == 0) ? {24'b0, sw[7:0]} : captured_read;
                writeEnable = 1;
                next_state  = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end
endmodule