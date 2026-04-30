`timescale 1ns / 1ps
module debouncer(
    input clk, pbin,
    output reg pbout
);
    reg [19:0] timer;
    reg [1:0] sync;

    always @(posedge clk) begin
        sync <= {sync[0], pbin};
        if (sync[1] == pbout) begin
            timer <= 0;
        end else begin
            timer <= timer + 1;
            if (timer == 20'hFFFFF) begin
                pbout <= sync[1];
                timer <= 0;
            end
        end
    end
endmodule
