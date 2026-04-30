`timescale 1ns/1ps
module tb_TaskC;

    reg         clk;
    reg         rst;
    reg  [15:0] sw_in;
    wire [15:0] led_out;

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    TopLevelProcessor uut (
        .clk            (clk),
        .rst            (rst),
        .sw_in          (sw_in),
        .led_out        (led_out),
        .dbgAluControl  (),
        .dbgRegWrite    (),
        .dbgMemRead     (),
        .dbgMemWrite    (),
        .dbgMemToReg    (),
        .dbgAluSrc      (),
        .dbgBranch      (),
        .dbgJump        (),
        .dbgJalr        (),
        .dbgZero        (),
        .dbgLessThan    (),
        .dbgPC          (),
        .dbgInstruction (),
        .dbgAluResult   ()
    );
    // Load programC.hex
    initial begin
//        $readmemh("C:/Users/IBM/Desktop/lab 11/CA_Labs_MyrahHussain_RomaisaShazad/CA_Lab11_Myrah_Romaisa/All_CA_Labs.srcs/sources_1/new/programC.hex", uut.u_instrMem.memory);
       $readmemh("C:/Users/IBM/Downloads/CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programC.hex", uut.u_instrMem.memory);
        $display("Instruction load check:");
        $display("  [0] = %h (expect 0fc00113)", uut.u_instrMem.memory[0]);
        $display("  [1] = %h (expect 10000413)", uut.u_instrMem.memory[1]);
    end

    integer cycle;
    reg [15:0] prev_led;

    initial begin
        $dumpfile("tb_TaskC.vcd");
        $dumpvars(0, tb_TaskC);

        rst   = 1;
        sw_in = 16'b0;
        prev_led = 0;
        repeat(5) @(posedge clk); #1;
        rst = 0;

        $display("=== Task C Simulation - Fibonacci Sequence ===");
        $display("Expected: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55...");
        $display("");

        // Watch for LED changes - each change is a new Fibonacci number
        for (cycle = 0; cycle < 5000; cycle = cycle + 1) begin
            @(posedge clk); #1;
            if (led_out != prev_led && led_out != 0) begin
                $display("Fibonacci term: %0d (cycle %0d)", led_out, cycle);
                prev_led = led_out;
            end
        end

        $display("");
        $display("=== Task C Simulation Complete ===");
        $finish;
    end

    // Timeout
    initial begin
        #5_000_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
