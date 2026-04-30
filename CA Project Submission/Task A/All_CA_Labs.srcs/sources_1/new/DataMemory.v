`timescale 1ns / 1ps
module DataMemory (
    input         clk,
    input         rst,
    input         memWrite,
    input         memRead,
    input  [2:0]  funct3,
    input  [31:0] address,
    input  [31:0] writeData,
    output reg [31:0] readData,
    output wire [31:0] ledData
);
    reg [31:0] memory [0:255];
    integer i;
    wire [31:0] word = memory[address[9:2]];
    wire [1:0]  boff = address[1:0];
    
    // LEDs always show memory[0]
    assign ledData = memory[0];
    
    // -------- WRITE (Synchronous) --------
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1)
                memory[i] <= 32'b0;
        end else if (memWrite) begin
            case (funct3)
                3'b000: begin
                    case (boff)
                        2'b00: memory[address[9:2]][7:0]   <= writeData[7:0];
                        2'b01: memory[address[9:2]][15:8]  <= writeData[7:0];
                        2'b10: memory[address[9:2]][23:16] <= writeData[7:0];
                        2'b11: memory[address[9:2]][31:24] <= writeData[7:0];
                    endcase
                end
                3'b001: begin
                    if (boff[1] == 1'b0)
                        memory[address[9:2]][15:0]  <= writeData[15:0];
                    else
                        memory[address[9:2]][31:16] <= writeData[15:0];
                end
                3'b010:
                    memory[address[9:2]] <= writeData;
                default:
                    memory[address[9:2]] <= writeData;
            endcase
        end
    end
    // -------- READ (Asynchronous) --------
    reg [7:0]  b;
    reg [15:0] h;
    always @(*) begin
        case (boff)
            2'b00: b = word[7:0];
            2'b01: b = word[15:8];
            2'b10: b = word[23:16];
            2'b11: b = word[31:24];
        endcase
        h = boff[1] ? word[31:16] : word[15:0];
        if (memRead) begin
            case (funct3)
                3'b000: readData = {{24{b[7]}},  b};
                3'b001: readData = {{16{h[15]}}, h};
                3'b010: readData = word;
                3'b100: readData = {24'b0, b};
                3'b101: readData = {16'b0, h};
                default: readData = word;
            endcase
        end else begin
            readData = 32'b0;
        end
    end
endmodule


//    // Synchronous write / reset
//    always @(posedge clk) begin
//        if (rst) begin
//            for (i = 0; i < 256; i = i + 1)
//                memory[i] <= 32'b0;
//        end else if (memWrite) begin
//            memory[address] <= writeData;
//        end
//    end

//    // Asynchronous read
//    assign readData = memory[address];
//endmodule
