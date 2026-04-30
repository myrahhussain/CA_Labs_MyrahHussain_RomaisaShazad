`timescale 1ns / 1ps
module clkDivider (
    input  wire clkIn,
    input  wire reset,
    output reg  clkOut
);
    reg [25:0] counter;

    always @(posedge clkIn or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clkOut  <= 0;
        end else begin
            if (counter == 26'd24_999_999) begin
                counter <= 0;
                clkOut  <= ~clkOut;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule