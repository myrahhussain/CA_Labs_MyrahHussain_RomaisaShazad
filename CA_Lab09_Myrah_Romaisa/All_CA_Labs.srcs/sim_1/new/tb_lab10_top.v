`timescale 1ns/1ps

module tb_lab10_top;

    reg         clk;
    reg         rst_btn;
    reg  [15:0] sw;
    wire [15:0] led;

    lab10_top dut (
        .clk     (clk),
        .rst_btn (rst_btn),
        .sw      (sw),
        .led     (led)
    );

    initial clk = 0;
    always #50 clk = ~clk;

    // Watchdog
    initial begin
        #10_000_000;
        $display("=== WATCHDOG TIMEOUT ===");
        $finish;
    end

    // Monitor - only prints when values change
    initial begin
        $monitor("[t=%8t] SW=%04h LED=%04h RST=%b",
                  $time, sw, led, rst_btn);
    end

    // Reset task - now only needs a few cycles
    task do_reset;
        begin
            rst_btn = 1;
            repeat(10) @(posedge clk);  // 10 cycles is enough
            rst_btn = 0;
            repeat(10) @(posedge clk);
        end
    endtask

    initial begin
        $display("=== Lab 10 FSM Simulation Start ===");
        rst_btn = 1;
        sw      = 16'h0000;
        repeat(10) @(posedge clk);
        rst_btn = 0;
        repeat(20) @(posedge clk);

        // REQ 1: After reset, LED must be 0
        $display("REQ1: LED after reset = %04h (expect 0000)", led);

        // REQ 2: SW=0 stays in waiting state
        sw = 16'h0000;
        repeat(200) @(posedge clk);
        $display("REQ2: LED with SW=0 = %04h (expect 0000)", led);

        // REQ 3: Countdown from 5
        // Step count: 5 steps * (10 delay + ~10 instr) = ~100 cycles min
        $display("REQ3: Starting countdown from 5...");
        sw = 16'h0005;
        repeat(30) @(posedge clk);
        sw = 16'h0000;
        repeat(50)  @(posedge clk);
        $display("      Mid-count LED = %04h (expect ~3-4)", led);
        repeat(500) @(posedge clk);
        $display("      Final LED = %04h (expect 0000)", led);

        // REQ 4: SW ignored during countdown
        $display("REQ4: SW ignored during countdown...");
        sw = 16'h0006;
        repeat(30) @(posedge clk);
        sw = 16'h0000;
        repeat(40) @(posedge clk);
        sw = 16'hFFFF;   // try to interrupt - must be ignored
        $display("      LED during ignored SW = %04h", led);
        sw = 16'h0000;
        repeat(500) @(posedge clk);
        $display("      Final LED = %04h (expect 0000)", led);

        // REQ 5: LEDs decrement visibly
        $display("REQ5: Visible decrement from 10 (0x000A)...");
        sw = 16'h000A;
        repeat(30) @(posedge clk);
        sw = 16'h0000;
        repeat(60)  @(posedge clk);
        $display("      Sample1 LED = %04h", led);
        repeat(100) @(posedge clk);
        $display("      Sample2 LED = %04h", led);
        repeat(100) @(posedge clk);
        $display("      Sample3 LED = %04h", led);
        repeat(600) @(posedge clk);
        $display("      Final LED = %04h (expect 0000)", led);

        // REQ 6: Reset mid-countdown clears immediately
        $display("REQ6: Reset during countdown from 8...");
        sw = 16'h0008;
        repeat(30) @(posedge clk);
        sw = 16'h0000;
        repeat(100) @(posedge clk);
        $display("      LED before reset = %04h (should be >0)", led);
        do_reset;
        $display("      LED after reset = %04h (expect 0000)", led);

        // REQ 7: System works normally after reset
        $display("REQ7: Normal operation after reset...");
        repeat(20) @(posedge clk);
        sw = 16'h0003;
        repeat(30) @(posedge clk);
        sw = 16'h0000;
        repeat(300) @(posedge clk);
        $display("      LED after countdown from 3 = %04h (expect 0000)", led);

        // REQ 8: Minimum value SW=1
        $display("REQ8: Countdown from 1 (minimum)...");
        sw = 16'h0001;
        repeat(30) @(posedge clk);
        sw = 16'h0000;
        repeat(200) @(posedge clk);
        $display("      LED after countdown from 1 = %04h (expect 0000)", led);

        // FINAL: System still idle
        $display("FINAL: System idle...");
        sw = 16'h0000;
        repeat(50) @(posedge clk);
        $display("      LED = %04h (expect 0000)", led);

        $display("=== Simulation Complete ===");
        $finish;
    end

endmodule