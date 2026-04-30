`timescale 1ns/1ps
module tb_TaskA;
    reg         clk;
    reg         rst;
    reg  [15:0] sw_in;
    wire [15:0] led_out;
    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;
    // Instantiate processor
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
    // Load instruction memory and verify first 3 instructions
    initial begin
        $readmemh("C:/Users/IBM/Desktop/taska_CA_LabProject_Final/taska_CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programA.hex", uut.u_instrMem.memory);
        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
        $display("  [1] = %h (expect 10000413)", uut.u_instrMem.memory[1]);
        $display("  [2] = %h (expect 20000493)", uut.u_instrMem.memory[2]);
    end
    integer cycle;
    initial begin
        $dumpfile("tb_TaskA.vcd");
        $dumpvars(0, tb_TaskA);
        // ---- Reset ----
        rst   = 1;
        sw_in = 16'b0;
        repeat(5) @(posedge clk); #1;
        rst = 0;
        $display("=== Task A Simulation ===");
        // ---- Test 1: IDLE state - switches = 0 ----
        $display("Test 1: switches=0, LEDs should stay 0");
        repeat(20) @(posedge clk); #1;
        $display("After 20 cycles sw=0: PC=%h LED=%h (expect 0000)", uut.PC, led_out);
        // ---- Test 2: Set switches = 5, watch countdown ----
        $display("");
        $display("Test 2: switches=5, expect LEDs 5->4->3->2->1->0");
        sw_in = 16'd5;
        for (cycle = 0; cycle < 150; cycle = cycle + 1) begin
            @(posedge clk); #1;
            $display("Cycle %0d: PC=%h LED=%0d", cycle, uut.PC, led_out);
        end
        // ---- Test 3: Clear switches, back to IDLE ----
        $display("");
        $display("Test 3: sw=0, expect LED=0");
        sw_in = 16'd0;
        repeat(20) @(posedge clk); #1;
        $display("LED after clearing: %0d (expect 0)", led_out);
        $display("=== Task A Simulation Complete ===");
        $finish;
    end
    // Timeout
    initial begin
        #500_000;
        $display("TIMEOUT");
        $finish;
    end
endmodule

//`timescale 1ns/1ps
//module tb_TaskA;

//    reg         clk;
//    reg         rst;
//    reg  [15:0] sw_in;
//    wire [15:0] led_out;

//    // Clock: 10ns period
//    initial clk = 0;
//    always #5 clk = ~clk;

//    // Instantiate processor
//    TopLevelProcessor uut (
//        .clk            (clk),
//        .rst            (rst),
//        .sw_in          (sw_in),
//        .led_out        (led_out),
//        .dbgAluControl  (),
//        .dbgRegWrite    (),
//        .dbgMemRead     (),
//        .dbgMemWrite    (),
//        .dbgMemToReg    (),
//        .dbgAluSrc      (),
//        .dbgBranch      (),
//        .dbgJump        (),
//        .dbgJalr        (),
//        .dbgZero        (),
//        .dbgLessThan    (),
//        .dbgPC          (),
//        .dbgInstruction (),
//        .dbgAluResult   ()
//    );
//    // Load instruction memory and verify first 3 instructions
//    initial begin
//        $readmemh("C:/Users/H.H/Desktop/taska_CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programA.hex", uut.u_instrMem.memory);        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
//        $display("  [1] = %h (expect 10000413)", uut.u_instrMem.memory[1]);
//        $display("  [2] = %h (expect 20000493)", uut.u_instrMem.memory[2]);
//    end


//    integer cycle;

//    initial begin
//        $dumpfile("tb_TaskA.vcd");
//        $dumpvars(0, tb_TaskA);

//        // ---- Reset ----
//        rst   = 1;
//        sw_in = 16'b0;
//        repeat(5) @(posedge clk); #1;
//        rst = 0;

//        $display("=== Task A Simulation ===");

//        // ---- Test 1: IDLE state - switches = 0 ----
//        $display("Test 1: switches=0, LEDs should stay 0");
//        repeat(20) @(posedge clk); #1;
//        $display("After 20 cycles sw=0: PC=%h LED=%h (expect 0000)", uut.PC, led_out);

//        // ---- Test 2: Set switches = 5, watch countdown ----
//        $display("");
//        $display("Test 2: switches=5, expect LEDs 5->4->3->2->1->0");
//        sw_in = 16'd5;

//        for (cycle = 0; cycle < 150; cycle = cycle + 1) begin
//            @(posedge clk); #1;
//            $display("Cycle %0d: PC=%h LED=%0d", cycle, uut.PC, led_out);
//        end

//        // ---- Test 3: Clear switches, back to IDLE ----
//        $display("");
//        $display("Test 3: sw=0, expect LED=0");
//        sw_in = 16'd0;
//        repeat(20) @(posedge clk); #1;
//        $display("LED after clearing: %0d (expect 0)", led_out);

//        $display("=== Task A Simulation Complete ===");
//        $finish;
//    end

//    // Timeout
//    initial begin
//        #500_000;
//        $display("TIMEOUT");
//        $finish;
//    end

//endmodule


//`timescale 1ns/1ps
//module tb_TaskA;

//    reg         clk;
//    reg         rst;
//    reg  [15:0] sw_in;
//    wire [15:0] led_out;

//    // Clock: 10ns period
//    initial clk = 0;
//    always #5 clk = ~clk;

//    // Instantiate processor
//    TopLevelProcessor uut (
//        .clk     (clk),
//        .rst     (rst),
//        .sw_in   (sw_in),
//        .led_out (led_out),
//        // debug ports - leave unconnected in tb
//        .dbgAluControl  (),
//        .dbgRegWrite    (),
//        .dbgMemRead     (),
//        .dbgMemWrite    (),
//        .dbgMemToReg    (),
//        .dbgAluSrc      (),
//        .dbgBranch      (),
//        .dbgJump        (),
//        .dbgJalr        (),
//        .dbgZero        (),
//        .dbgLessThan    (),
//        .dbgPC          (),
//        .dbgInstruction ()
//    );

//    // Load instruction memory
//  initial begin
//    $readmemh("C:/Users/IBM/Desktop/lab 11/CA_Labs_MyrahHussain_RomaisaShazad/CA_Lab11_Myrah_Romaisa/All_CA_Labs.srcs/sources_1/new/programA.hex", uut.u_instrMem.memory);
//end
//$display("First instruction: %h (expect 08000113)", uut.u_instrMem.memory[0]);

//    integer cycle;

//    initial begin
//        $dumpfile("tb_TaskA.vcd");
//        $dumpvars(0, tb_TaskA);

//        // Reset
//        rst   = 1;
//        sw_in = 16'b0;
//        repeat(5) @(posedge clk); #1;
//        rst = 0;

//        $display("=== Task A Simulation ===");
//        $display("Testing IDLE state - switches = 0, LEDs should stay 0");

//        // Run 20 cycles with switches = 0 (IDLE loop)
//        repeat(20) @(posedge clk); #1;
//        $display("After 20 cycles with sw=0: PC=%h LED=%h (expect LED=0)",
//            uut.PC, led_out);

//        // Now raise switches to 5 - should trigger countdown
//        $display("");
//        $display("Setting switches = 5, expect countdown 5->4->3->2->1->0 on LEDs");
//        sw_in = 16'd5;

//        // Watch LEDs for 100 cycles
//        for (cycle = 0; cycle < 100; cycle = cycle + 1) begin
//            @(posedge clk); #1;
//            if (led_out != 0)
//                $display("Cycle %0d: PC=%h LED=%0d", cycle, uut.PC, led_out);
//        end

//        $display("");
//        $display("Setting switches = 0 again (back to IDLE)");
//        sw_in = 16'd0;
//        repeat(20) @(posedge clk); #1;
//        $display("LED after clearing switches: %0d (expect 0)", led_out);

//        $display("=== Task A Simulation Complete ===");
//        $finish;
//    end

//    // Timeout
//    initial begin
//        #500_000;
//        $display("TIMEOUT");
//        $finish;
//    end

//endmodule