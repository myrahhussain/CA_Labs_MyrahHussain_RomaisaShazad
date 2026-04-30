`timescale 1ns / 1ps
module RegisterFile (
    input  wire        clk,
    input  wire        rst,
    input  wire        WriteEnable,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] WriteData,
    output reg  [31:0] ReadData1,
    output reg  [31:0] ReadData2
);
    reg [31:0] regs [0:31];
    integer i;

    // Combinational read - x0 always reads 0
    always @(*) begin
        ReadData1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
        ReadData2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
    end

    // Synchronous write, x0 always stays 0
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0;
        end else begin
            if (WriteEnable && rd != 5'b0)
                regs[rd] <= WriteData;
        end
    end
endmodule

//`timescale 1ns / 1ps
//module RegisterFile (
//    input wire clk,
//    input wire rst,
//    input wire WriteEnable,
//    input wire [4:0] rs1,
//    input wire [4:0] rs2,
//    input wire [4:0] rd,
//    input wire [31:0] WriteData,
//    output reg [31:0] ReadData1,
//    output reg [31:0] ReadData2
//);

//    reg [31:0] regs [0:31];
//    integer i;

//    // Read Logic - no x0 check needed
//    // regs[0] is always maintained as 0 by write logic
//    always @(*) begin
//        ReadData1 = regs[rs1];
//        ReadData2 = regs[rs2];
//    end

//    // Write Logic - always force regs[0] = 0 after any write
//    always @(posedge clk) begin
//        if (rst) begin
//            for (i = 0; i < 32; i = i + 1)
//                regs[i] <= 32'h0;
//        end
//        else begin
//            if (WriteEnable)
//                regs[rd] <= WriteData;
//            // Always keep x0 hardwired to 0
//            // even if someone tried to write to it
//            regs[0] <= 32'h0;
//        end
//    end

//endmodule


//module RegisterFile (
//    input wire clk,
//    input wire rst,
//    input wire WriteEnable,
//    input wire [4:0] rs1,
//    input wire [4:0] rs2,
//    input wire [4:0] rd,
//    input wire [31:0] WriteData,
//    output reg [31:0] ReadData1,
//    output reg [31:0] ReadData2
//);

//    reg [31:0] regs [0:31];
//    integer i;

//    // Read Logic — no x0 check needed
//    // regs[0] is always maintained as 0 by write logic
//    always @(*) begin
//        ReadData1 = regs[rs1];
//        ReadData2 = regs[rs2];
//    end

//    // Write Logic — always force regs[0] = 0 after any write
//    always @(posedge clk) begin
//        if (rst) begin
//            for (i = 0; i < 32; i = i + 1)
//                regs[i] <= 32'h0;
//        end
//        else begin
//            if (WriteEnable)
//                regs[rd] <= WriteData;
//            // Always keep x0 hardwired to 0
//            // even if someone tried to write to it
//            regs[0] <= 32'h0;
//        end
//    end

//endmodule