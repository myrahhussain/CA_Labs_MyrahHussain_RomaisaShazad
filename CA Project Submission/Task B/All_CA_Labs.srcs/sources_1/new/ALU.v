`timescale 1ns / 1ps
module ALU (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUControl,
    output reg [31:0] ALUResult,
    output Zero,
    output LessThan
);
    wire [31:0] b_input;
    wire [31:0] carry;
    wire [31:0] structural_res;

    assign b_input  = (ALUControl == 4'b0110) ? ~B : B;
    wire first_cin  = (ALUControl == 4'b0110) ? 1'b1 : 1'b0;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : alu_slice
            if (i == 0)
                ALU_1bit bit0 (.a(A[i]), .b(b_input[i]), .cin(first_cin),
                               .op(ALUControl), .res(structural_res[i]), .cout(carry[i]));
            else
                ALU_1bit bitN (.a(A[i]), .b(b_input[i]), .cin(carry[i-1]),
                               .op(ALUControl), .res(structural_res[i]), .cout(carry[i]));
        end
    endgenerate

    always @(*) begin
        case (ALUControl)
            4'b0000: ALUResult = A >> B[4:0];    // SRL
            4'b0011: ALUResult = A << B[4:0];    // SLL
            default: ALUResult = structural_res; // ADD, SUB, AND, OR, XOR
        endcase
    end

    assign Zero     = (ALUResult == 32'b0);
    // LessThan: sign bit of subtraction result (A - B)
    // Only meaningful when ALUControl = SUB (0110)
    assign LessThan = structural_res[31];

endmodule



//    assign Zero = (ALUResult == 32'b0);
//endmodule