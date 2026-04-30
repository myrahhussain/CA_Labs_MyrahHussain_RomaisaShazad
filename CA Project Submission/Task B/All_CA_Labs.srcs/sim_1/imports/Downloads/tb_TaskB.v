`timescale 1ns/1ps
module tb_TaskB;
    reg         clk;
    reg         rst;
    reg  [15:0] sw_in;
    wire [15:0] led_out;
    wire [3:0]  dbgAluControl;
    wire        dbgRegWrite;
    wire        dbgMemRead;
    wire        dbgMemWrite;
    wire        dbgMemToReg;
    wire        dbgAluSrc;
    wire        dbgBranch;
    wire        dbgJump;
    wire        dbgJalr;
    wire        dbgZero;
    wire        dbgLessThan;
    wire [31:0] dbgPC;
    wire [31:0] dbgInstruction;

    initial clk = 0;
    always #5 clk = ~clk;

    TopLevelProcessor uut (
        .clk            (clk),
        .rst            (rst),
        .sw_in          (sw_in),
        .led_out        (led_out),
        .led_out32      (),
        .dbgAluControl  (dbgAluControl),
        .dbgRegWrite    (dbgRegWrite),
        .dbgMemRead     (dbgMemRead),
        .dbgMemWrite    (dbgMemWrite),
        .dbgMemToReg    (dbgMemToReg),
        .dbgAluSrc      (dbgAluSrc),
        .dbgBranch      (dbgBranch),
        .dbgPCSrc       (),
        .dbgBGETaken    (),
        .dbgJump        (dbgJump),
        .dbgJalr        (dbgJalr),
        .dbgZero        (dbgZero),
        .dbgLessThan    (dbgLessThan),
        .dbgPC          (dbgPC),
        .dbgInstruction (dbgInstruction),
        .dbgAluResult   ()
    );

    initial begin
        // reset first
        rst   = 1;
        sw_in = 16'b0;
        repeat(5) @(posedge clk); #1;
        rst = 0;

        // load hex AFTER reset
        $readmemh("C:/Users/IBM/Desktop/taskb_CA_LabProject_Final/taskb_CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programB.hex", uut.u_instrMem.memory);
        $display("Instruction load check:");
        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
        $display("  [1] = %h (expect 00000413 - x8=0)", uut.u_instrMem.memory[1]);
        $display("  [4] = %h (expect 0004a503 - LW)", uut.u_instrMem.memory[4]);

        repeat(2) @(posedge clk); #1;
    end

    always @(posedge clk) begin
        if (dbgJump)
            $display("t=%0t JAL  executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
        if (dbgJalr)
            $display("t=%0t JALR executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
        if (dbgBranch)
            $display("t=%0t BGE  executing | PC=%h | LessThan=%b | Branch taken=%b",
                      $time, dbgPC, dbgLessThan, ~dbgLessThan);
    end

    initial begin
        $dumpfile("tb_TaskB.vcd");
        $dumpvars(0, tb_TaskB);

        rst   = 1;
        sw_in = 16'b0;
        repeat(5) @(posedge clk); #1;
        rst = 0;
        repeat(5) @(posedge clk); #1;

        $display("=== Task B Simulation ===");

        // ---- Test 1: sw=0 IDLE ----
        $display("Test 1: sw=0, expect LED=0 (IDLE)");
        sw_in = 16'd0;
        repeat(20) @(posedge clk); #1;
        $display("LED = %0d (expect 0)", led_out);

        // ---- Test 2: sw=4 small path expect LED=8 ----
        $display("");
        $display("Test 2: sw=4 (< 8) BGE NOT taken, DOUBLE, expect LED=8");
        sw_in = 16'd4;
        repeat(50) @(posedge clk); #1;
        sw_in = 16'd0;
        repeat(20) @(posedge clk); #1;
        $display("LED = %0d (expect 8)", led_out);
        repeat(30) @(posedge clk); #1;

        // ---- Test 3: sw=8 boundary expect LED=4 ----
        $display("");
        $display("Test 3: sw=8 (= 8) BGE TAKEN boundary, HALVE, expect LED=4");
        sw_in = 16'd8;
        repeat(50) @(posedge clk); #1;
        sw_in = 16'd0;
        repeat(20) @(posedge clk); #1;
        $display("LED = %0d (expect 4)", led_out);
        repeat(30) @(posedge clk); #1;

        // ---- Test 4: sw=12 big path expect LED=6 ----
        $display("");
        $display("Test 4: sw=12 (>= 8) BGE TAKEN, HALVE, expect LED=6");
        sw_in = 16'd12;
        repeat(50) @(posedge clk); #1;
        sw_in = 16'd0;
        repeat(20) @(posedge clk); #1;
        $display("LED = %0d (expect 6)", led_out);
        repeat(30) @(posedge clk); #1;

        // ---- Test 5: sw=6 small path expect LED=12 ----
        $display("");
        $display("Test 5: sw=6 (< 8) BGE NOT taken, DOUBLE, expect LED=12");
        sw_in = 16'd6;
        repeat(50) @(posedge clk); #1;
        sw_in = 16'd0;
        repeat(20) @(posedge clk); #1;
        $display("LED = %0d (expect 12)", led_out);

        $display("");
        $display("=== Task B Simulation Complete ===");
        $finish;
    end

    initial begin
        #2_000_000;
        $display("TIMEOUT");
        #100;
        $finish;
    end
endmodule

//`timescale 1ns/1ps
//module tb_TaskB;
//    reg         clk;
//    reg         rst;
//    reg  [15:0] sw_in;
//    wire [15:0] led_out;
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite;
//    wire        dbgMemRead;
//    wire        dbgMemWrite;
//    wire        dbgMemToReg;
//    wire        dbgAluSrc;
//    wire        dbgBranch;
//    wire        dbgJump;
//    wire        dbgJalr;
//    wire        dbgZero;
//    wire        dbgLessThan;
//    wire [31:0] dbgPC;
//    wire [31:0] dbgInstruction;

//    initial clk = 0;
//    always #5 clk = ~clk;

//    TopLevelProcessor uut (
//        .clk            (clk),
//        .rst            (rst),
//        .sw_in          (sw_in),
//        .led_out        (led_out),
//        .led_out32      (),
//        .dbgAluControl  (dbgAluControl),
//        .dbgRegWrite    (dbgRegWrite),
//        .dbgMemRead     (dbgMemRead),
//        .dbgMemWrite    (dbgMemWrite),
//        .dbgMemToReg    (dbgMemToReg),
//        .dbgAluSrc      (dbgAluSrc),
//        .dbgBranch      (dbgBranch),
//        .dbgPCSrc       (),
//        .dbgBGETaken    (),
//        .dbgJump        (dbgJump),
//        .dbgJalr        (dbgJalr),
//        .dbgZero        (dbgZero),
//        .dbgLessThan    (dbgLessThan),
//        .dbgPC          (dbgPC),
//        .dbgInstruction (dbgInstruction),
//        .dbgAluResult   ()
//    );

//    initial begin
//        $readmemh("C:/Users/IBM/Desktop/taskb_CA_LabProject_Final/taskb_CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programB.hex", uut.u_instrMem.memory);
//        $display("Instruction load check:");
//        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
//        $display("  [1] = %h (expect 00000413 - x8=0)", uut.u_instrMem.memory[1]);
//        $display("  [4] = %h (expect 0004a503 - LW)", uut.u_instrMem.memory[4]);
//    end

//    always @(posedge clk) begin
//        if (dbgJump)
//            $display("t=%0t JAL  executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
//        if (dbgJalr)
//            $display("t=%0t JALR executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
//        if (dbgBranch)
//            $display("t=%0t BGE  executing | PC=%h | LessThan=%b | Branch taken=%b",
//                      $time, dbgPC, dbgLessThan, ~dbgLessThan);
//    end

//    initial begin
//        $dumpfile("tb_TaskB.vcd");
//        $dumpvars(0, tb_TaskB);

//        rst   = 1; #10;
//        sw_in = 16'b0;
//        rst   = 0; #10;

//        $display("=== Task B Simulation ===");

//        // ---- Test 1: sw=0 IDLE ----
//        $display("Test 1: sw=0, expect LED=0 (IDLE)");
//        repeat(20) @(posedge clk); #1;
//        $display("LED = %0d (expect 0)", led_out);

//        // ---- Test 2: sw=4 small path doubleIt expect LED=8 ----
//        $display("");
//        $display("Test 2: sw=4 (< 8) BGE NOT taken, DOUBLE, expect LED=8");
//        sw_in = 16'd4;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 8)", led_out);

//        sw_in = 16'd0;
//        repeat(50) @(posedge clk); #1;

//        // ---- Test 3: sw=8 boundary halveIt expect LED=4 ----
//        $display("");
//        $display("Test 3: sw=8 (= 8) BGE TAKEN boundary, HALVE, expect LED=4");
//        sw_in = 16'd8;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 4)", led_out);

//        sw_in = 16'd0;
//        repeat(50) @(posedge clk); #1;

//        // ---- Test 4: sw=12 big path halveIt expect LED=6 ----
//        $display("");
//        $display("Test 4: sw=12 (>= 8) BGE TAKEN, HALVE, expect LED=6");
//        sw_in = 16'd12;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 6)", led_out);

//        sw_in = 16'd0;
//        repeat(50) @(posedge clk); #1;

//        // ---- Test 5: sw=6 small path doubleIt expect LED=12 ----
//        $display("");
//        $display("Test 5: sw=6 (< 8) BGE NOT taken, DOUBLE, expect LED=12");
//        sw_in = 16'd6;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 12)", led_out);

//        $display("");
//        $display("=== Task B Simulation Complete ===");
//        $finish;
//    end

//    initial begin
//        #500_000;
//        $display("TIMEOUT");
//        #100;
//        $finish;
//    end
//endmodule

//`timescale 1ns/1ps
//module tb_TaskB;
//    reg         clk;
//    reg         rst;
//    reg  [15:0] sw_in;
//    wire [15:0] led_out;
//    wire [3:0]  dbgAluControl;
//    wire        dbgRegWrite;
//    wire        dbgMemRead;
//    wire        dbgMemWrite;
//    wire        dbgMemToReg;
//    wire        dbgAluSrc;
//    wire        dbgBranch;
//    wire        dbgJump;
//    wire        dbgJalr;
//    wire        dbgZero;
//    wire        dbgLessThan;
//    wire [31:0] dbgPC;
//    wire [31:0] dbgInstruction;
//    initial clk = 0;
//    always #5 clk = ~clk;
//    TopLevelProcessor uut (
//        .clk            (clk),
//        .rst            (rst),
//        .sw_in          (sw_in),
//        .led_out        (led_out),
//        .led_out32      (),
//        .dbgAluControl  (dbgAluControl),
//        .dbgRegWrite    (dbgRegWrite),
//        .dbgMemRead     (dbgMemRead),
//        .dbgMemWrite    (dbgMemWrite),
//        .dbgMemToReg    (dbgMemToReg),
//        .dbgAluSrc      (dbgAluSrc),
//        .dbgBranch      (dbgBranch),
//        .dbgPCSrc       (),
//        .dbgBGETaken    (),
//        .dbgJump        (dbgJump),
//        .dbgJalr        (dbgJalr),
//        .dbgZero        (dbgZero),
//        .dbgLessThan    (dbgLessThan),
//        .dbgPC          (dbgPC),
//        .dbgInstruction (dbgInstruction),
//        .dbgAluResult   ()
//    );
//    initial begin
//        $readmemh("C:/Users/IBM/Desktop/taskb_CA_LabProject_Final/taskb_CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programB.hex", uut.u_instrMem.memory);
//        $display("Instruction load check:");
//        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
//        $display("  [1] = %h (expect 00000413 - x8=0)", uut.u_instrMem.memory[1]);
//        $display("  [4] = %h (expect 0004a503 - LW)", uut.u_instrMem.memory[4]);
//    end
//    always @(posedge clk) begin
//        if (dbgJump)
//            $display("t=%0t JAL  executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
//        if (dbgJalr)
//            $display("t=%0t JALR executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
//        if (dbgBranch)
//            $display("t=%0t BGE  executing | PC=%h | LessThan=%b | Branch taken=%b",
//                      $time, dbgPC, dbgLessThan, ~dbgLessThan);
//    end
//    initial begin
//        $dumpfile("tb_TaskB.vcd");
//        $dumpvars(0, tb_TaskB);
//        rst   = 1; #10;
//        sw_in = 16'b0;
//        rst   = 0; #10;
//        $display("=== Task B Simulation ===");
//        $display("Test 1: sw=0, expect LED=0 (IDLE)");
//        repeat(20) @(posedge clk); #1;
//        $display("LED = %0d (expect 0)", led_out);
//        $display("");
//        $display("Test 2: sw=4 (< 8) BGE NOT taken, DOUBLE, expect LED=8");
//        sw_in = 16'd4;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 8)", led_out);
//        sw_in = 16'd0;
//        repeat(50) @(posedge clk); #1;
//        $display("");
//        $display("Test 3: sw=12 (>= 8) BGE TAKEN, HALVE, expect LED=6");
//        sw_in = 16'd12;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 6)", led_out);
//        sw_in = 16'd0;
//        repeat(50) @(posedge clk); #1;
//        $display("");
//        $display("Test 4: sw=8 (= 8) BGE TAKEN, HALVE, expect LED=4");
//        sw_in = 16'd8;
//        repeat(100) @(posedge clk); #1;
//        $display("LED = %0d (expect 4)", led_out);
//        $display("");
//        $display("=== Task B Simulation Complete ===");
//        $finish;
//    end
//    initial begin
//        #500_000;
//        $display("TIMEOUT");
//        #100;
//        $finish;
//    end
//endmodule

////`timescale 1ns/1ps
////module tb_TaskB;

////    reg         clk;
////    reg         rst;
////    reg  [15:0] sw_in;
////    wire [15:0] led_out;
////    wire [3:0]  dbgAluControl;
////    wire        dbgRegWrite;
////    wire        dbgMemRead;
////    wire        dbgMemWrite;
////    wire        dbgMemToReg;
////    wire        dbgAluSrc;
////    wire        dbgBranch;
////    wire        dbgJump;
////    wire        dbgJalr;
////    wire        dbgZero;
////    wire        dbgLessThan;
////    wire [31:0] dbgPC;
////    wire [31:0] dbgInstruction;

////    initial clk = 0;
////    always #5 clk = ~clk;

////    TopLevelProcessor uut (
////        .clk            (clk),
////        .rst            (rst),
////        .sw_in          (sw_in),
////        .led_out        (led_out),
////        .dbgAluControl  (dbgAluControl),
////        .dbgRegWrite    (dbgRegWrite),
////        .dbgMemRead     (dbgMemRead),
////        .dbgMemWrite    (dbgMemWrite),
////        .dbgMemToReg    (dbgMemToReg),
////        .dbgAluSrc      (dbgAluSrc),
////        .dbgBranch      (dbgBranch),
////        .dbgPCSrc       (),
////        .dbgBGETaken    (),
////        .dbgJump        (dbgJump),
////        .dbgJalr        (dbgJalr),
////        .dbgZero        (dbgZero),
////        .dbgLessThan    (dbgLessThan),
////        .dbgPC          (dbgPC),
////        .dbgInstruction (dbgInstruction),
////        .dbgAluResult   (),
////        .led_out32      ()
////    );

////    initial begin
////        $readmemh("C:/Users/H.H/Desktop/taskb_CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programB.hex", uut.u_instrMem.memory);        $display("Instruction load check:");
////        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
////        $display("  [1] = %h (expect 00000413 - x8=0)", uut.u_instrMem.memory[1]);
////        $display("  [4] = %h (expect lw instruction)", uut.u_instrMem.memory[4]);
////    end

////    always @(posedge clk) begin
////        if (dbgJump)
////            $display("t=%0t JAL  executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
////        if (dbgJalr)
////            $display("t=%0t JALR executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
////        if (dbgBranch)
////            $display("t=%0t BGE  executing | PC=%h | LessThan=%b | Branch taken=%b",
////                      $time, dbgPC, dbgLessThan, ~dbgLessThan);
////    end

////    initial begin
////        $dumpfile("tb_TaskB.vcd");
////        $dumpvars(0, tb_TaskB);

////        rst   = 1;
////        sw_in = 16'b0;
////        repeat(5) @(posedge clk); #1;
////        rst = 0;

////        $display("=== Task B Simulation ===");

////        $display("Test 1: sw=0, expect LED=0 (IDLE)");
////        repeat(20) @(posedge clk); #1;
////        $display("LED = %0d (expect 0)", led_out);

////        $display("");
////        $display("Test 2: sw=4 (< 8) BGE NOT taken, DOUBLE, expect LED=8");
////        sw_in = 16'd4;
////        repeat(100) @(posedge clk); #1;
////        $display("LED = %0d (expect 8)", led_out);

////        sw_in = 16'd0;
////        repeat(50) @(posedge clk); #1;

////        $display("");
////        $display("Test 3: sw=12 (>= 8) BGE TAKEN, HALVE, expect LED=6");
////        sw_in = 16'd12;
////        repeat(100) @(posedge clk); #1;
////        $display("LED = %0d (expect 6)", led_out);

////        sw_in = 16'd0;
////        repeat(50) @(posedge clk); #1;

////        $display("");
////        $display("Test 4: sw=8 (= 8) BGE TAKEN, HALVE, expect LED=4");
////        sw_in = 16'd8;
////        repeat(100) @(posedge clk); #1;
////        $display("LED = %0d (expect 4)", led_out);

////        $display("");
////        $display("=== Task B Simulation Complete ===");
////        $finish;
////    end

////    initial begin
////        #500_000;
////        $display("TIMEOUT");
////        $finish;
////    end

////endmodule

////`timescale 1ns/1ps
////module tb_TaskB;

////    reg         clk;
////    reg         rst;
////    reg  [15:0] sw_in;
////    wire [15:0] led_out;
////    wire        dbgPCSrc;

////    initial clk = 0;
////    always #5 clk = ~clk;

////    TopLevelProcessor uut (
////        .clk            (clk),
////        .rst            (rst),
////        .sw_in          (sw_in),
////        .led_out        (led_out),
////        .dbgAluControl  (),
////        .dbgRegWrite    (),
////        .dbgMemRead     (),
////        .dbgMemWrite    (),
////        .dbgMemToReg    (),
////        .dbgAluSrc      (),
////        .dbgBranch      (),
////        .dbgPCSrc       (dbgPCSrc),
////        .dbgJump        (),
////        .dbgJalr        (),
////        .dbgZero        (),
////        .dbgLessThan    (),
////        .dbgPC          (),
////        .dbgInstruction (),
////        .dbgAluResult   ()
////    );

////    initial begin
////        $dumpfile("tb_TaskB.vcd");
////        $dumpvars(0, tb_TaskB);
////    end

////    initial begin
////        // ================================================
////        // RESET
////        // ================================================
////        rst   = 1;
////        sw_in = 16'b0;
////        repeat(5) @(posedge clk); #1;
////        rst = 0;

////        // Load hex AFTER reset
////`timescale 1ns/1ps
////module tb_TaskB;
////    reg         clk;
////    reg         rst;
////    reg  [15:0] sw_in;
////    wire [15:0] led_out;
////    wire [3:0]  dbgAluControl;
////    wire        dbgRegWrite;
////    wire        dbgMemRead;
////    wire        dbgMemWrite;
////    wire        dbgMemToReg;
////    wire        dbgAluSrc;
////    wire        dbgBranch;
////    wire        dbgJump;
////    wire        dbgJalr;
////    wire        dbgZero;
////    wire        dbgLessThan;
////    wire [31:0] dbgPC;
////    wire [31:0] dbgInstruction;

////    initial clk = 0;
////    always #5 clk = ~clk;

////    TopLevelProcessor uut (
////        .clk            (clk),
////        .rst            (rst),
////        .sw_in          (sw_in),
////        .led_out        (led_out),
////        .dbgAluControl  (dbgAluControl),
////        .dbgRegWrite    (dbgRegWrite),
////        .dbgMemRead     (dbgMemRead),
////        .dbgMemWrite    (dbgMemWrite),
////        .dbgMemToReg    (dbgMemToReg),
////        .dbgAluSrc      (dbgAluSrc),
////        .dbgBranch      (dbgBranch),
////        .dbgJump        (dbgJump),
////        .dbgJalr        (dbgJalr),
////        .dbgZero        (dbgZero),
////        .dbgLessThan    (dbgLessThan),
////        .dbgPC          (dbgPC),
////        .dbgInstruction (dbgInstruction)
////    );

////    initial begin
////        $readmemh("C:/Users/IBM/Desktop/CA_LabProject_Finalfromlab/CA_LabProject_Final/All_CA_Labs.srcs/sources_1/new/programB.hex", uut.u_instrMem.memory);
////        $display("Instruction load check:");
////        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
////        $display("  [1] = %h (expect 00000413 - x8=0)", uut.u_instrMem.memory[1]);
////        $display("  [4] = %h (expect lw instruction)", uut.u_instrMem.memory[4]);
////    end

////    always @(posedge clk) begin
////        if (dbgJump)
////            $display("t=%0t JAL  executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
////        if (dbgJalr)
////            $display("t=%0t JALR executing | PC=%h | instr=%h", $time, dbgPC, dbgInstruction);
////        if (dbgBranch)
////            $display("t=%0t BGE  executing | PC=%h | LessThan=%b | Branch taken=%b",
////                      $time, dbgPC, dbgLessThan, ~dbgLessThan);
////    end

////    initial begin
////        $dumpfile("tb_TaskB.vcd");
////        $dumpvars(0, tb_TaskB);
////        rst   = 1; #10;
////        sw_in = 16'b0;
////        rst   = 0; #10;
////        $display("=== Task B Simulation ===");

////        $display("Test 1: sw=0, expect LED=0 (IDLE)");
////        repeat(20) @(posedge clk); #1;
////        $display("LED = %0d (expect 0)", led_out);

////        $display("");
////        $display("Test 2: sw=4 (< 8) BGE NOT taken, DOUBLE, expect LED=8");
////        sw_in = 16'd4;
////        repeat(100) @(posedge clk); #1;
////        $display("LED = %0d (expect 8)", led_out);

////        sw_in = 16'd0;
////        repeat(50) @(posedge clk); #1;

////        $display("");
////        $display("Test 3: sw=12 (>= 8) BGE TAKEN, HALVE, expect LED=6");
////        sw_in = 16'd12;
////        repeat(100) @(posedge clk); #1;
////        $display("LED = %0d (expect 6)", led_out);

////        sw_in = 16'd0;
////        repeat(50) @(posedge clk); #1;

////        $display("");
////        $display("Test 4: sw=8 (= 8) BGE TAKEN, HALVE, expect LED=4");
////        sw_in = 16'd8;
////        repeat(100) @(posedge clk); #1;
////        $display("LED = %0d (expect 4)", led_out);

////        $display("");
////        $display("=== Task B Simulation Complete ===");
////        $finish;
////    end

////    initial begin
////        #500_000;
////        $display("TIMEOUT");
////        #100;
////        $finish;
////    end
////endmodule        repeat(2) @(posedge clk); #1;

////        // ================================================
////        // TEST 1 - sw=0 IDLE
////        // ================================================
////        $display("TEST 1: sw=0 idle expect LED=0");
////        sw_in = 16'd0;
////        repeat(15) @(posedge clk); #1;
////        $display("  LED=%0d (expect 0)", led_out);
////        if (led_out === 16'd0) $display("  PASS");
////        else $display("  FAIL");

////        // ================================================
////        // TEST 2 - sw=4 SMALL PATH
////        // ================================================
////        $display("");
////        $display("TEST 2: sw=4 small path expect LED=8");
////        sw_in = 16'd4;
////        // Give processor enough time to read switches, execute BGE, JAL, doubleIt, return, SW
////        repeat(50) @(posedge clk); #1;
////        $display("  LED=%0d (expect 8)  PCSrc=%b (expect 0 at BGE)", led_out, dbgPCSrc);
////        if (led_out === 16'd8) $display("  PASS doubleIt");
////        else $display("  FAIL doubleIt LED=%0d", led_out);

////        // ================================================
////        // TEST 3 - sw=0 BETWEEN TESTS
////        // ================================================
////        sw_in = 16'd0;
////        repeat(15) @(posedge clk); #1;

////        // ================================================
////        // TEST 4 - sw=12 BIG PATH
////        // ================================================
////        $display("");
////        $display("TEST 3: sw=12 big path expect LED=6");
////        sw_in = 16'd12;
////        repeat(50) @(posedge clk); #1;
////        $display("  LED=%0d (expect 6)  PCSrc=%b (expect 1 at BGE)", led_out, dbgPCSrc);
////        if (led_out === 16'd6) $display("  PASS halveIt");
////        else $display("  FAIL halveIt LED=%0d", led_out);

////        // ================================================
////        // TEST 5 - sw=0 BETWEEN TESTS
////        // ================================================
////        sw_in = 16'd0;
////        repeat(15) @(posedge clk); #1;

////        // ================================================
////        // TEST 6 - sw=8 BOUNDARY
////        // ================================================
////        $display("");
////        $display("TEST 4: sw=8 boundary expect LED=4");
////        sw_in = 16'd8;
////        repeat(50) @(posedge clk); #1;
////        $display("  LED=%0d (expect 4)  PCSrc=%b (expect 1 at BGE)", led_out, dbgPCSrc);
////        if (led_out === 16'd4) $display("  PASS boundary");
////        else $display("  FAIL boundary LED=%0d", led_out);

////        // ================================================
////        // SUMMARY
////        // ================================================
////        $display("");
////        $display("========================================");
////        $display("SUMMARY");
////        $display("  sw=4  -> LED=8  BGE not taken");
////        $display("  sw=12 -> LED=6  BGE taken");
////        $display("  sw=8  -> LED=4  BGE boundary taken");
////        $display("========================================");
////        $finish;
////    end

////    initial begin
////        #200_000;
////        $display("TIMEOUT");
////        $finish;
////    end

////endmodule

//////`timescale 1ns / 1ps

//////// ============================================================
//////// tb_TaskB_detailed.v
//////// Tests LUI, BGE, JAL one at a time with full signal display
//////// Add these signals to your waveform window:
////////   clk, rst, sw_in, led_out
////////   dbgPC, dbgInstruction
////////   dbgAluControl, dbgRegWrite, dbgAluSrc
////////   dbgMemRead, dbgMemWrite, dbgMemToReg
////////   dbgBranch, dbgJump, dbgJalr
////////   dbgZero, dbgLessThan
////////   uut.u_regFile.regs[10]   <- x10 (switch value / result)
////////   uut.u_regFile.regs[11]   <- x11 (threshold = 8)
////////   uut.u_regFile.regs[12]   <- x12 (LED address = 0x100)
////////   uut.u_regFile.regs[1]    <- x1  (return address)
//////// ============================================================

//////module tb_TaskB_detailed;

//////    // --------------------------------------------------------
//////    // DUT signals
//////    // --------------------------------------------------------
//////    reg         clk;
//////    reg         rst;
//////    reg  [15:0] sw_in;
//////    wire [15:0] led_out;

//////    wire [3:0]  dbgAluControl;
//////    wire        dbgRegWrite, dbgMemRead, dbgMemWrite;
//////    wire        dbgMemToReg, dbgAluSrc, dbgBranch;
//////    wire        dbgJump, dbgJalr, dbgZero, dbgLessThan;
//////    wire [31:0] dbgPC, dbgInstruction;

//////    // --------------------------------------------------------
//////    // Clock: 10ns period
//////    // --------------------------------------------------------
//////    initial clk = 0;
//////    always #5 clk = ~clk;

//////    // --------------------------------------------------------
//////    // DUT
//////    // --------------------------------------------------------
//////  TopLevelProcessor uut (
//////        .clk            (clk),
//////        .rst            (rst),
//////        .sw_in          (sw_in),
//////        .led_out        (led_out),
//////        .dbgAluControl  (),
//////        .dbgRegWrite    (),
//////        .dbgMemRead     (),
//////        .dbgMemWrite    (),
//////        .dbgMemToReg    (),
//////        .dbgAluSrc      (),
//////        .dbgBranch      (),
//////        .dbgJump        (),
//////        .dbgJalr        (),
//////        .dbgZero        (),
//////        .dbgLessThan    (),
//////        .dbgPC          (),
//////        .dbgInstruction (),
//////        .dbgAluResult   ()
//////    );

//////    // --------------------------------------------------------
//////    // Load hex
//////    // --------------------------------------------------------
//////    initial begin
//////$readmemh("C:/Users/IBM/Desktop/CA Labs FULLLLL shehryar/CA_Labs/Project/ProgramB.hex", uut.u_instrMem.memory);
//////        $display("=== HEX LOAD CHECK ===");
//////        $display("  inst[0]  = %h  (expect 08000113 ADDI)", uut.u_instrMem.memory[0]);
//////        $display("  inst[4]  = %h  (expect 00001637 LUI)",  uut.u_instrMem.memory[4]);
//////        $display("  inst[8]  = %h  (expect 00B55863 BGE)",  uut.u_instrMem.memory[8]);
//////        $display("  inst[9]  = %h  (expect 018000EF JAL doubleIt)", uut.u_instrMem.memory[9]);
//////        $display("  inst[12] = %h  (expect 014000EF JAL halveIt)",  uut.u_instrMem.memory[12]);
//////        $display("");
//////        if (uut.u_instrMem.memory[9]  !== 32'h018000EF)
//////            $display("  ERROR: inst[9] wrong! Fix your programB.hex");
//////        if (uut.u_instrMem.memory[12] !== 32'h014000EF)
//////            $display("  ERROR: inst[12] wrong! Fix your programB.hex");
//////    end

//////    // --------------------------------------------------------
//////    // Waveform dump
//////    // --------------------------------------------------------
//////    initial begin
//////        $dumpfile("tb_TaskB_detailed.vcd");
//////        $dumpvars(0, tb_TaskB_detailed);
//////    end

//////    // --------------------------------------------------------
//////    // Helper task: print one line per clock showing
//////    // PC, instruction, and key signals
//////    // --------------------------------------------------------
//////    task print_cycle;
//////        input [63:0] label_unused; // just for readability
//////        begin
//////            @(posedge clk); #1;
//////            $display("  PC=%02d  inst=%h  ALUCtrl=%b  RW=%b AS=%b MR=%b MW=%b BR=%b JMP=%b JALR=%b Z=%b LT=%b  x10=%0d x1=%0d  LED=%0d",
//////                dbgPC,
//////                dbgInstruction,
//////                dbgAluControl,
//////                dbgRegWrite,
//////                dbgAluSrc,
//////                dbgMemRead,
//////                dbgMemWrite,
//////                dbgBranch,
//////                dbgJump,
//////                dbgJalr,
//////                dbgZero,
//////                dbgLessThan,
//////                uut.u_regFile.regs[10],
//////                uut.u_regFile.regs[1],
//////                led_out
//////            );
//////        end
//////    endtask

//////    // --------------------------------------------------------
//////    // Helper: wait until PC reaches a target value
//////    // Timeout after 50 cycles
//////    // --------------------------------------------------------
//////    task wait_for_pc;
//////        input [31:0] target;
//////        integer count;
//////        begin
//////            count = 0;
//////            while (dbgPC !== target && count < 50) begin
//////                @(posedge clk); #1;
//////                count = count + 1;
//////            end
//////            if (count >= 50)
//////                $display("  TIMEOUT waiting for PC=%0d", target);
//////        end
//////    endtask

//////    // --------------------------------------------------------
//////    // MAIN TEST
//////    // --------------------------------------------------------
//////    integer i;

//////    initial begin
//////        rst   = 1;
//////        sw_in = 16'b0;
//////        repeat(5) @(posedge clk); #1;
//////        rst = 0;

//////        // ==================================================
//////        // PHASE 1: WATCH INIT INSTRUCTIONS (inst 0-5)
//////        // These run once at startup before the poll loop
//////        // Look for: LUI at PC=16
//////        // ==================================================
//////        $display("");
//////        $display("========================================");
//////        $display("PHASE 1: INIT SEQUENCE (inst[0] to inst[5])");
//////        $display("Watch: PC steps 0,4,8,12,16,20");
//////        $display("At PC=16: LUI executes - RegWrite=1, ALUSrc=1, Branch=0, Jump=0");
//////        $display("At PC=20: SRLI executes - ALUControl=0000 (SRL)");
//////        $display("Columns: PC inst ALUCtrl RW AS MR MW BR JMP JALR Z LT  x10 x1  LED");
//////        $display("----------------------------------------");

//////        // inst[0] ADDI x2,x0,128
//////        @(posedge clk); #1;
//////        $display("  PC=%02d  inst=%h  [ADDI x2,x0,128  -> x2=128]  ALUCtrl=%b RW=%b AS=%b",
//////            dbgPC, dbgInstruction, dbgAluControl, dbgRegWrite, dbgAluSrc);

//////        // inst[1] ADDI x8,x0,256
//////        @(posedge clk); #1;
//////        $display("  PC=%02d  inst=%h  [ADDI x8,x0,256  -> x8=256]  ALUCtrl=%b RW=%b AS=%b",
//////            dbgPC, dbgInstruction, dbgAluControl, dbgRegWrite, dbgAluSrc);

//////        // inst[2] ADDI x9,x0,512
//////        @(posedge clk); #1;
//////        $display("  PC=%02d  inst=%h  [ADDI x9,x0,512  -> x9=512]  ALUCtrl=%b RW=%b AS=%b",
//////            dbgPC, dbgInstruction, dbgAluControl, dbgRegWrite, dbgAluSrc);

//////        // inst[3] ADDI x11,x0,8
//////        @(posedge clk); #1;
//////        $display("  PC=%02d  inst=%h  [ADDI x11,x0,8   -> x11=8]   ALUCtrl=%b RW=%b AS=%b",
//////            dbgPC, dbgInstruction, dbgAluControl, dbgRegWrite, dbgAluSrc);

//////        // ==================================================
//////        // *** LUI INSTRUCTION ***
//////        // inst[4] PC=16  0x00001637  LUI x12, 0x1
//////        // ==================================================
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** LUI INSTRUCTION ***");
//////        $display("  PC=%02d  inst=%h  [LUI x12,0x1]", dbgPC, dbgInstruction);
//////        $display("  RegWrite   = %b  (expect 1 - writes x12)", dbgRegWrite);
//////        $display("  ALUSrc     = %b  (expect 1 - uses immediate)", dbgAluSrc);
//////        $display("  MemRead    = %b  (expect 0)", dbgMemRead);
//////        $display("  MemWrite   = %b  (expect 0)", dbgMemWrite);
//////        $display("  Branch     = %b  (expect 0)", dbgBranch);
//////        $display("  Jump       = %b  (expect 0)", dbgJump);
//////        $display("  ALUControl = %b  (expect 0010 = ADD, ALUOp=00)", dbgAluControl);
//////        $display("  x12 before = %0d  (will become 4096=0x1000 after clk edge)",
//////            uut.u_regFile.regs[12]);
//////        $display("  LUI verification: instruction[31:12]=00000000000000000001");
//////        $display("                    => x12 = 0x00001000 = 4096");
//////        if (dbgInstruction === 32'h00001637)
//////            $display("  PASS: correct LUI instruction loaded");
//////        else
//////            $display("  FAIL: wrong instruction at PC=16, got %h", dbgInstruction);

//////        // inst[5] SRLI x12,x12,4
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  inst[5] SRLI x12,x12,4");
//////        $display("  PC=%02d  inst=%h  ALUControl=%b  (expect 0000=SRL)", dbgPC, dbgInstruction, dbgAluControl);
//////        $display("  x12 before SRLI = %0d (should be 4096)", uut.u_regFile.regs[12]);
//////        @(posedge clk); #1; // let it write
//////        $display("  x12 after  SRLI = %0d (should be 256=0x100 = LED address)", uut.u_regFile.regs[12]);

//////        // ==================================================
//////        // PHASE 2: IDLE LOOP (sw=0)
//////        // inst[6] LW, inst[7] BEQ loops back
//////        // ==================================================
//////        $display("");
//////        $display("========================================");
//////        $display("PHASE 2: IDLE LOOP (sw=0)");
//////        $display("Watch: PC oscillates between 24 and 28");
//////        $display("inst[6] LW reads 0, inst[7] BEQ taken (Zero=1), loops back");
//////        $display("----------------------------------------");

//////        sw_in = 16'd0;
//////        repeat(6) begin
//////            @(posedge clk); #1;
//////            $display("  PC=%02d  inst=%h  BR=%b Z=%b  x10=%0d  LED=%0d  (idle loop)",
//////                dbgPC, dbgInstruction, dbgBranch, dbgZero,
//////                uut.u_regFile.regs[10], led_out);
//////        end

//////        // ==================================================
//////        // PHASE 3: BGE TEST + JAL doubleIt  (sw=4)
//////        // ==================================================
//////        $display("");
//////        $display("========================================");
//////        $display("PHASE 3: sw=4 -> BGE not taken -> JAL doubleIt");
//////        $display("Expected: LED = 8");
//////        $display("Watch: BGE at PC=32 has LessThan=1 (4<8), branch NOT taken");
//////        $display("       JAL at PC=36 jumps to PC=60 (doubleIt)");
//////        $display("----------------------------------------");

//////        sw_in = 16'd4;

//////        // Wait until we hit inst[6] again with new sw value
//////        wait_for_pc(32'd24);

//////        // inst[6] LW - reads sw=4
//////        @(posedge clk); #1;
//////        $display("  inst[6] PC=%02d  LW x10,0(x9)  MR=%b MtR=%b  x10=%0d  (reads sw=4)",
//////            dbgPC, dbgMemRead, dbgMemToReg, uut.u_regFile.regs[10]);

//////        // inst[7] BEQ x10,x0,-4
//////        @(posedge clk); #1;
//////        $display("  inst[7] PC=%02d  BEQ x10,x0,-4  BR=%b Z=%b  x10=%0d  (x10!=0 so NOT taken)",
//////            dbgPC, dbgBranch, dbgZero, uut.u_regFile.regs[10]);

//////        // *** BGE INSTRUCTION ***
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** BGE INSTRUCTION (sw=4, expect NOT taken) ***");
//////        $display("  PC=%02d  inst=%h  [BGE x10,x11,+16]", dbgPC, dbgInstruction);
//////        $display("  Branch     = %b  (expect 1)", dbgBranch);
//////        $display("  LessThan   = %b  (expect 1, because 4 < 8, so 4-8 is negative)", dbgLessThan);
//////        $display("  Zero       = %b  (expect 0, 4-8 != 0)", dbgZero);
//////        $display("  takeBranch = ~LessThan = %b  (expect 0 = NOT taken)", ~dbgLessThan);
//////        $display("  ALUControl = %b  (expect 0110 = SUB, ALUOp=01)", dbgAluControl);
//////        $display("  x10=%0d  x11=%0d  (comparing these two)",
//////            uut.u_regFile.regs[10], uut.u_regFile.regs[11]);
//////        if (dbgLessThan === 1'b1 && dbgBranch === 1'b1)
//////            $display("  PASS: BGE correctly NOT taken for sw=4");
//////        else
//////            $display("  FAIL: BGE state wrong");

//////        // *** JAL INSTRUCTION (doubleIt call) ***
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** JAL INSTRUCTION (call doubleIt) ***");
//////        $display("  PC=%02d  inst=%h  [JAL x1,+24]", dbgPC, dbgInstruction);
//////        $display("  Jump       = %b  (expect 1)", dbgJump);
//////        $display("  RegWrite   = %b  (expect 1, saves return addr in x1)", dbgRegWrite);
//////        $display("  x1 before  = %0d  (will become 40 = return addr)", uut.u_regFile.regs[1]);
//////        $display("  Next PC should jump to 60 (inst[15] doubleIt body)");
//////        if (dbgInstruction === 32'h018000EF)
//////            $display("  PASS: correct JAL instruction");
//////        else
//////            $display("  FAIL: wrong instruction, got %h (check programB.hex line 10)", dbgInstruction);

//////        // inst[15] ADD x10,x10,x10  (doubleIt body)
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  inst[15] PC=%02d  ADD x10,x10,x10  [doubleIt body]", dbgPC);
//////        $display("  ALUControl = %b  (expect 0010 = ADD)", dbgAluControl);
//////        $display("  ALUSrc     = %b  (expect 0, R-type uses register not imm)", dbgAluSrc);
//////        $display("  RegWrite   = %b  (expect 1)", dbgRegWrite);
//////        $display("  x10 before = %0d  (should be 4)", uut.u_regFile.regs[10]);
//////        $display("  x1  now    = %0d  (should be 40 = return addr saved by JAL)", uut.u_regFile.regs[1]);
//////        if (dbgPC === 32'd60)
//////            $display("  PASS: PC=60 confirms JAL jumped to doubleIt correctly");
//////        else
//////            $display("  FAIL: PC=%0d, expected 60", dbgPC);

//////        // inst[16] JALR (return from doubleIt)
//////        @(posedge clk); #1;
//////        $display("  inst[16] PC=%02d  JALR x0,x1,0  [return from doubleIt]", dbgPC);
//////        $display("  Jalr       = %b  (expect 1)", dbgJalr);
//////        $display("  x10 now    = %0d  (should be 8 after doubling)", uut.u_regFile.regs[10]);
//////        $display("  x1         = %0d  (return addr, next PC will be this)", uut.u_regFile.regs[1]);

//////        // inst[10] BEQ x0,x0,+12 (skip to store)
//////        @(posedge clk); #1;
//////        $display("  inst[10] PC=%02d  BEQ x0,x0,+12  BR=%b Z=%b  (always taken, goes to SW)",
//////            dbgPC, dbgBranch, dbgZero);

//////        // inst[13] SW (store to LEDs)
//////        @(posedge clk); #1;
//////        $display("  inst[13] PC=%02d  SW x10,0(x12)  MW=%b  x10=%0d  LED=%0d",
//////            dbgPC, dbgMemWrite, uut.u_regFile.regs[10], led_out);

//////        // inst[14] BEQ loop-back
//////        @(posedge clk); #1;
//////        $display("  inst[14] PC=%02d  BEQ x0,x0,-32  BR=%b Z=%b  (loops back to inst[6])",
//////            dbgPC, dbgBranch, dbgZero);

//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  RESULT sw=4: LED=%0d  (expect 8)", led_out);
//////        if (led_out === 16'd8)
//////            $display("  PASS doubleIt");
//////        else
//////            $display("  FAIL doubleIt (check JAL offset in programB.hex)");

//////        // ==================================================
//////        // PHASE 4: Reset sw to 0 between tests
//////        // ==================================================
//////        $display("");
//////        $display("  Resetting sw to 0...");
//////        sw_in = 16'd0;
//////        repeat(4) @(posedge clk); #1;

//////        // ==================================================
//////        // PHASE 5: BGE TEST + JAL halveIt  (sw=12)
//////        // ==================================================
//////        $display("");
//////        $display("========================================");
//////        $display("PHASE 5: sw=12 -> BGE taken -> JAL halveIt");
//////        $display("Expected: LED = 6");
//////        $display("Watch: BGE at PC=32 has LessThan=0 (12>=8), branch TAKEN");
//////        $display("       JAL at PC=48 jumps to PC=68 (halveIt)");
//////        $display("----------------------------------------");

//////        sw_in = 16'd12;
//////        wait_for_pc(32'd24);

//////        // inst[6] LW
//////        @(posedge clk); #1;
//////        $display("  inst[6] PC=%02d  LW  MR=%b  x10=%0d  (reads sw=12)",
//////            dbgPC, dbgMemRead, uut.u_regFile.regs[10]);

//////        // inst[7] BEQ
//////        @(posedge clk); #1;
//////        $display("  inst[7] PC=%02d  BEQ BR=%b Z=%b  x10=%0d  (not taken, x10!=0)",
//////            dbgPC, dbgBranch, dbgZero, uut.u_regFile.regs[10]);

//////        // *** BGE INSTRUCTION (taken this time) ***
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** BGE INSTRUCTION (sw=12, expect TAKEN) ***");
//////        $display("  PC=%02d  inst=%h  [BGE x10,x11,+16]", dbgPC, dbgInstruction);
//////        $display("  Branch     = %b  (expect 1)", dbgBranch);
//////        $display("  LessThan   = %b  (expect 0, because 12 >= 8, 12-8=4 is positive)", dbgLessThan);
//////        $display("  Zero       = %b  (expect 0)", dbgZero);
//////        $display("  takeBranch = ~LessThan = %b  (expect 1 = TAKEN)", ~dbgLessThan);
//////        $display("  x10=%0d  x11=%0d", uut.u_regFile.regs[10], uut.u_regFile.regs[11]);
//////        $display("  Next PC should jump to 48 (inst[12] JAL halveIt)");
//////        if (dbgLessThan === 1'b0 && dbgBranch === 1'b1)
//////            $display("  PASS: BGE correctly TAKEN for sw=12");
//////        else
//////            $display("  FAIL: BGE state wrong for sw=12");

//////        // *** JAL INSTRUCTION (halveIt call) ***
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** JAL INSTRUCTION (call halveIt) ***");
//////        $display("  PC=%02d  inst=%h  [JAL x1,+20]", dbgPC, dbgInstruction);
//////        $display("  Jump       = %b  (expect 1)", dbgJump);
//////        $display("  RegWrite   = %b  (expect 1, saves return addr)", dbgRegWrite);
//////        $display("  x1 before  = %0d  (will become 52)", uut.u_regFile.regs[1]);
//////        $display("  Next PC should jump to 68 (inst[17] halveIt body)");
//////        if (dbgPC === 32'd48 && dbgInstruction === 32'h014000EF)
//////            $display("  PASS: correct JAL halveIt instruction at PC=48");
//////        else if (dbgInstruction !== 32'h014000EF)
//////            $display("  FAIL: wrong instruction %h at PC=%0d (check programB.hex line 13)", dbgInstruction, dbgPC);

//////        // inst[17] SRLI x10,x10,1 (halveIt body)
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  inst[17] PC=%02d  SRLI x10,x10,1  [halveIt body]", dbgPC);
//////        $display("  ALUControl = %b  (expect 0000 = SRL)", dbgAluControl);
//////        $display("  ALUSrc     = %b  (expect 1, shift amount is immediate)", dbgAluSrc);
//////        $display("  RegWrite   = %b  (expect 1)", dbgRegWrite);
//////        $display("  x10 before = %0d  (should be 12)", uut.u_regFile.regs[10]);
//////        $display("  x1  now    = %0d  (should be 52 = return addr saved by JAL)", uut.u_regFile.regs[1]);
//////        if (dbgPC === 32'd68)
//////            $display("  PASS: PC=68 confirms JAL jumped to halveIt correctly");
//////        else
//////            $display("  FAIL: PC=%0d expected 68", dbgPC);

//////        // inst[18] JALR (return from halveIt)
//////        @(posedge clk); #1;
//////        $display("  inst[18] PC=%02d  JALR x0,x1,0  [return from halveIt]", dbgPC);
//////        $display("  Jalr       = %b  (expect 1)", dbgJalr);
//////        $display("  x10 now    = %0d  (should be 6 after halving 12)", uut.u_regFile.regs[10]);
//////        $display("  x1         = %0d  (return addr = 52 = inst[13])", uut.u_regFile.regs[1]);

//////        // inst[13] SW
//////        @(posedge clk); #1;
//////        $display("  inst[13] PC=%02d  SW x10,0(x12)  MW=%b  x10=%0d  LED=%0d",
//////            dbgPC, dbgMemWrite, uut.u_regFile.regs[10], led_out);

//////        // inst[14] loop-back
//////        @(posedge clk); #1;
//////        $display("  inst[14] PC=%02d  BEQ x0,x0,-32  (loops back)", dbgPC);

//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  RESULT sw=12: LED=%0d  (expect 6)", led_out);
//////        if (led_out === 16'd6)
//////            $display("  PASS halveIt");
//////        else
//////            $display("  FAIL halveIt (check JAL offset in programB.hex)");

//////        // ==================================================
//////        // PHASE 6: sw=0 reset then boundary sw=8
//////        // ==================================================
//////        $display("");
//////        $display("  Resetting sw to 0...");
//////        sw_in = 16'd0;
//////        repeat(4) @(posedge clk); #1;

//////        $display("");
//////        $display("========================================");
//////        $display("PHASE 6: sw=8 BOUNDARY -> BGE taken (8>=8) -> halveIt");
//////        $display("Expected: LED = 4");
//////        $display("Watch: BGE ALU computes 8-8=0, sign bit=0, LessThan=0, branch TAKEN");
//////        $display("       Zero=1 but BGE ignores Zero, uses LessThan only");
//////        $display("----------------------------------------");

//////        sw_in = 16'd8;
//////        wait_for_pc(32'd24);

//////        // inst[6]
//////        @(posedge clk); #1;
//////        $display("  inst[6] PC=%02d  LW  x10=%0d  (reads sw=8)", dbgPC, uut.u_regFile.regs[10]);

//////        // inst[7]
//////        @(posedge clk); #1;
//////        $display("  inst[7] PC=%02d  BEQ BR=%b Z=%b  (x10=8, not taken)", dbgPC, dbgBranch, dbgZero);

//////        // *** BGE boundary case ***
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** BGE BOUNDARY CASE (sw=8, exactly equal to threshold) ***");
//////        $display("  PC=%02d  inst=%h", dbgPC, dbgInstruction);
//////        $display("  x10=%0d  x11=%0d  (8-8=0)", uut.u_regFile.regs[10], uut.u_regFile.regs[11]);
//////        $display("  LessThan   = %b  (expect 0: result=0, sign bit=0, not negative)", dbgLessThan);
//////        $display("  Zero       = %b  (expect 1: 8-8=0)", dbgZero);
//////        $display("  takeBranch = ~LessThan = %b  (expect 1 = TAKEN, BGE includes equal)", ~dbgLessThan);
//////        $display("  KEY POINT: Zero=1 but BGE does NOT use Zero signal.");
//////        $display("             BGE only checks LessThan. Since 8 is not less than 8,");
//////        $display("             LessThan=0 so branch is taken. Equal counts as >= ");
//////        if (dbgLessThan === 1'b0 && dbgZero === 1'b1)
//////            $display("  PASS: boundary case correct");
//////        else
//////            $display("  FAIL: unexpected state");

//////        // JAL halveIt
//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  *** JAL (call halveIt for sw=8) ***");
//////        $display("  PC=%02d  inst=%h  Jump=%b RegWrite=%b", dbgPC, dbgInstruction, dbgJump, dbgRegWrite);

//////        // halveIt body
//////        @(posedge clk); #1;
//////        $display("  inst[17] PC=%02d  SRLI  x10=%0d before  (should be 8)",
//////            dbgPC, uut.u_regFile.regs[10]);

//////        // JALR return
//////        @(posedge clk); #1;
//////        $display("  inst[18] PC=%02d  JALR  x10=%0d  (should be 4 after 8>>1)",
//////            dbgPC, uut.u_regFile.regs[10]);

//////        // SW store
//////        @(posedge clk); #1;
//////        $display("  inst[13] PC=%02d  SW  LED=%0d  (expect 4)", dbgPC, led_out);

//////        @(posedge clk); #1;
//////        $display("");
//////        $display("  RESULT sw=8: LED=%0d  (expect 4)", led_out);
//////        if (led_out === 16'd4)
//////            $display("  PASS boundary");
//////        else
//////            $display("  FAIL boundary");

//////        // ==================================================
//////        // PHASE 7: LUI specific re-check
//////        // We already saw LUI in phase 1. This section
//////        // summarises what to look for in the waveform
//////        // ==================================================
//////        $display("");
//////        $display("========================================");
//////        $display("WAVEFORM GUIDE - what to look for");
//////        $display("========================================");
//////        $display("");
//////        $display("LUI (inst[4] PC=16 hex=00001637):");
//////        $display("  In waveform zoom to t~91ns");
//////        $display("  dbgInstruction  = 00001637");
//////        $display("  dbgRegWrite     = 1");
//////        $display("  dbgAluSrc       = 1");
//////        $display("  dbgBranch       = 0");
//////        $display("  dbgJump         = 0");
//////        $display("  dbgAluControl   = 0010  (ADD, always for ALUOp=00)");
//////        $display("  regs[12] goes from 0 -> 4096 (0x1000) after this clock");
//////        $display("  then inst[5] SRLI shifts it to 256 (0x100)");
//////        $display("");
//////        $display("BGE (inst[8] PC=32 hex=00B55863):");
//////        $display("  In waveform find where dbgPC=32 and dbgInstruction=00B55863");
//////        $display("  With sw=4:  dbgLessThan=1, dbgBranch=1, next PC=36  (not taken)");
//////        $display("  With sw=12: dbgLessThan=0, dbgBranch=1, next PC=48  (taken)");
//////        $display("  With sw=8:  dbgLessThan=0, dbgZero=1,   next PC=48  (taken)");
//////        $display("  dbgAluControl = 0110 (SUB) for all branch instructions");
//////        $display("");
//////        $display("JAL doubleIt (inst[9] PC=36 hex=018000EF):");
//////        $display("  In waveform find dbgPC=36 dbgInstruction=018000EF");
//////        $display("  dbgJump=1, dbgRegWrite=1");
//////        $display("  next PC jumps from 36 to 60 (skips over 40,44,48,52,56)");
//////        $display("  regs[1] = 40 after this");
//////        $display("");
//////        $display("JAL halveIt (inst[12] PC=48 hex=014000EF):");
//////        $display("  In waveform find dbgPC=48 dbgInstruction=014000EF");
//////        $display("  dbgJump=1, dbgRegWrite=1");
//////        $display("  next PC jumps from 48 to 68 (skips over 52,56,60,64)");
//////        $display("  regs[1] = 52 after this");
//////        $display("");
//////        $display("========================================");
//////        $display("FINAL SUMMARY");
//////        $display("========================================");
//////        $display("  sw=0  -> LED=0   idle");
//////        $display("  sw=4  -> LED=8   doubleIt (4*2=8)");
//////        $display("  sw=12 -> LED=6   halveIt  (12/2=6)");
//////        $display("  sw=8  -> LED=4   halveIt  (8/2=4)");

//////        $finish;
//////    end

//////    // Timeout
//////    initial begin
//////        #50000;
//////        $display("TIMEOUT");
//////        $finish;
//////    end

//////endmodule

////////`timescale 1ns/1ps
////////module tb_TaskB;

////////    reg         clk;
////////    reg         rst;
////////    reg  [15:0] sw_in;
////////    wire [15:0] led_out;

////////    // Clock: 10ns period
////////    initial clk = 0;
////////    always #5 clk = ~clk;

////////    // Instantiate processor
////////    TopLevelProcessor uut (
////////        .clk            (clk),
////////        .rst            (rst),
////////        .sw_in          (sw_in),
////////        .led_out        (led_out),
////////        .dbgAluControl  (),
////////        .dbgRegWrite    (),
////////        .dbgMemRead     (),
////////        .dbgMemWrite    (),
////////        .dbgMemToReg    (),
////////        .dbgAluSrc      (),
////////        .dbgBranch      (),
////////        .dbgJump        (),
////////        .dbgJalr        (),
////////        .dbgZero        (),
////////        .dbgLessThan    (),
////////        .dbgPC          (),
////////        .dbgInstruction ()
////////    );

////////    // Load programB.hex
////////    initial begin
////////        $readmemh("C:/Users/IBM/Desktop/lab 11/CA_Labs_MyrahHussain_RomaisaShazad/CA_Lab11_Myrah_Romaisa/All_CA_Labs.srcs/sources_1/new/programB.hex", uut.u_instrMem.memory);
////////        $display("Instruction load check:");
////////        $display("  [0] = %h (expect 08000113)", uut.u_instrMem.memory[0]);
////////        $display("  [4] = %h (expect 00001637 - LUI)", uut.u_instrMem.memory[4]);
////////    end

////////    initial begin
////////        $dumpfile("tb_TaskB.vcd");
////////        $dumpvars(0, tb_TaskB);

////////        // Reset
////////        rst   = 1;
////////        sw_in = 16'b0;
////////        repeat(5) @(posedge clk); #1;
////////        rst = 0;

////////        $display("=== Task B Simulation ===");

////////        // ---- Test 1: IDLE - switches = 0 ----
////////        $display("Test 1: sw=0, expect LED=0 (IDLE)");
////////        repeat(10) @(posedge clk); #1;
////////        $display("LED = %0d (expect 0)", led_out);

////////        // ---- Test 2: sw=4 (small path) doubleIt: expect LED=8 ----
////////        $display("");
////////        $display("Test 2: sw=4 (< 8, small path) doubleIt, expect LED=8");
////////        sw_in = 16'd4;
////////        repeat(30) @(posedge clk); #1;
////////        $display("LED = %0d (expect 8)", led_out);

////////        // ---- Test 3: sw=0 back to idle ----
////////        sw_in = 16'd0;
////////        repeat(10) @(posedge clk); #1;

////////        // ---- Test 4: sw=12 (big path) halveIt: expect LED=6 ----
////////        $display("");
////////        $display("Test 3: sw=12 (>= 8, big path) halveIt, expect LED=6");
////////        sw_in = 16'd12;
////////        repeat(30) @(posedge clk); #1;
////////        $display("LED = %0d (expect 6)", led_out);

////////        // ---- Test 5: sw=0 back to idle ----
////////        sw_in = 16'd0;
////////        repeat(10) @(posedge clk); #1;

////////        // ---- Test 6: sw=8 (boundary) halveIt: expect LED=4 ----
////////        $display("");
////////        $display("Test 4: sw=8 (= 8, big path) halveIt, expect LED=4");
////////        sw_in = 16'd8;
////////        repeat(30) @(posedge clk); #1;
////////        $display("LED = %0d (expect 4)", led_out);

////////        $display("");
////////        $display("=== Task B Simulation Complete ===");
////////        $finish;
////////    end

////////    // Timeout
////////    initial begin
////////        #500_000;
////////        $display("TIMEOUT");
////////        $finish;
////////    end

////////endmodule
