`timescale 1ns / 1ps
module ALU_1bit (
    input        a,
    input        b,
    input        cin,
    input  [3:0] op,
    output reg   res,
    output       cout
);
    wire w_sum;
    assign {cout, w_sum} = a + b + cin;

    always @(*) begin
        case (op)
            4'b0010: res = w_sum;  // ADD
            4'b0110: res = w_sum;  // SUB
            4'b1000: res = a & b;  // AND
            4'b0001: res = a | b;  // OR
            4'b0111: res = a ^ b;  // XOR
            default: res = 1'b0;
        endcase
    end
endmodule
//`timescale 1ns/1ps
//module ALU_1bit (
//    input  a,
//    input  b,
//    input  cin,
//    input  [3:0] op,
//    output reg res,
//    output cout
//);
//    wire w_sum;
//    assign {cout, w_sum} = a + b + cin;

//    always @(*) begin
//        case (op)
//            4'b0010: res = w_sum;  // ADD  ? matches ALUControl 0010
//            4'b0110: res = w_sum;  // SUB  ? matches ALUControl 0110
//            4'b1000: res = a & b;  // AND  ? matches ALUControl 1000
//            4'b0001: res = a | b;  // OR   ? matches ALUControl 0001
//            4'b0111: res = a ^ b;  // XOR  ? matches ALUControl 0111
//            default: res = 1'b0;
//        endcase
//    end
//endmodule




////`timescale 1ns / 1ps
////module ALU_1bit (
////    input a,
////    input b,
////    input cin,
////    input [3:0] op,
////    output reg res,
////    output cout
////);
////    wire w_sum;
////    // Full Adder Logic (Used for ADD and SUB)
////    assign {cout, w_sum} = a + b + cin;
////    always @(*) begin
////        case (op)
////            4'b0000: res = w_sum; // ADD
////            4'b0001: res = w_sum; // SUB
////            4'b0010: res = a & b; // AND
////            4'b0011: res = a | b; // OR
////            4'b0100: res = a ^ b; // XOR
//////4'b0111: res = w_sum; // BEQ/SUB Helper
////            default: res = 1'b0;
////        endcase
////     end
////endmodule
   