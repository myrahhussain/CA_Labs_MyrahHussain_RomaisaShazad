`timescale 1ns / 1ps
// =========================================================
// top_lab09.v
// Top-level FPGA wrapper for RISC-V Control Path Lab 9
//
// Switch mapping (SW[15:0]):
//   SW[15:9]  = opcode[6:0]   ? instruction bits [6:0]
//   SW[8:6]   = funct3[2:0]   ? instruction bits [14:12]
//   SW[5]     = funct7[5]     ? instruction bit  [30]
//              (only bit of funct7 needed; rest are 0 for RV32I)
//   SW[4:0]   = unused
//
// LED mapping (LED[15:0]):
//   LED[15]   = RegWrite
//   LED[14]   = ALUSrc
//   LED[13]   = MemRead
//   LED[12]   = MemWrite
//   LED[11]   = MemtoReg
//   LED[10]   = Branch
//   LED[9:8]  = ALUOp[1:0]
//   LED[7:4]  = ALUControl[3:0]
//   LED[3:2]  = FSM state[1:0]
//   LED[1:0]  = unused
//
// FSM states:
//   IDLE     (00) - waiting for button press
//   SAMPLE   (01) - latch switch values
//   DISPLAY  (10) - drive LEDs with control signals
//   WAIT_REL (11) - wait for button release
// =========================================================

module top_lab09 (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] sw,   // 16 FPGA slide switches
    input  wire        btn,  // push button (step/sample)
    output wire [15:0] led   // 16 FPGA LEDs
);

    // ---- Debounce the push button ----
    wire btn_clean;
    debouncer u_deb (
        .clk   (clk),
        .pbin  (btn),
        .pbout (btn_clean)
    );

    // ---- Instantiate switches module (Lab 5) ----
    wire [31:0] sw_readData;
    switches u_sw (
        .clk        (clk),
        .rst        (rst),
        .btns       (16'b0),
        .writeData  (32'b0),
        .writeEnable(1'b0),
        .readEnable (1'b1),
        .memAddress (30'b0),
        .switches   (sw),
        .readData   (sw_readData)
    );

    // ---- Extract fields from switches module output ----
    // SW[15:9] ? opcode   (instruction bits [6:0])
    // SW[8:6]  ? funct3   (instruction bits [14:12])
    // SW[5]    ? funct7[5](instruction bit  [30])
    wire [6:0] sw_opcode = sw_readData[15:9];
    wire [2:0] sw_funct3 = sw_readData[8:6];
    wire [6:0] sw_funct7 = {1'b0, sw_readData[5], 5'b0}; // funct7[5] from SW[5]

    // ---- Latched instruction fields (set by FSM) ----
    reg [6:0] opcode_r;
    reg [2:0] funct3_r;
    reg [6:0] funct7_r;

    // ---- Control signal wires ----
    wire       RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUControl;

    // ---- Instantiate Main Control ----
    MainControl u_main (
        .opcode   (opcode_r),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    // ---- Instantiate ALU Control ----
    ALUControl u_alu (
        .ALUOp      (ALUOp),
        .funct3     (funct3_r),
        .funct7     (funct7_r),   // full 7 bits [31:25] of instruction
        .ALUControl (ALUControl)
    );

    // ---- LED data register ----
    reg [15:0] led_data;

    // ---- Instantiate leds module (Lab 5) ----
    leds u_leds (
        .clk         (clk),
        .rst         (rst),
        .writeData   ({16'b0, led_data}),
        .writeEnable (1'b1),
        .readEnable  (1'b0),
        .memAddress  (30'b0),
        .readData    (),
        .leds        (led)
    );

    // ---- FSM ----
    localparam IDLE     = 2'b00;
    localparam SAMPLE   = 2'b01;
    localparam DISPLAY  = 2'b10;
    localparam WAIT_REL = 2'b11;

    reg [1:0] state, next_state;
    reg       btn_prev;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            btn_prev <= 1'b0;
        end else begin
            state    <= next_state;
            btn_prev <= btn_clean;
        end
    end

    // Rising-edge detection
    wire btn_rise = btn_clean & ~btn_prev;

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:     if (btn_rise)   next_state = SAMPLE;
            SAMPLE:                   next_state = DISPLAY;
            DISPLAY:  if (!btn_clean) next_state = WAIT_REL;
            WAIT_REL: if (!btn_clean) next_state = IDLE;
            default:                  next_state = IDLE;
        endcase
    end

    // Output / datapath logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            funct7_r <= 7'b0;
            led_data <= 16'b0;
        end else begin
            case (state)
                SAMPLE: begin
                    opcode_r <= sw_opcode;
                    funct3_r <= sw_funct3;
                    funct7_r <= sw_funct7;
                end
                DISPLAY: begin
                    led_data[15]  <= RegWrite;
                    led_data[14]  <= ALUSrc;
                    led_data[13]  <= MemRead;
                    led_data[12]  <= MemWrite;
                    led_data[11]  <= MemtoReg;
                    led_data[10]  <= Branch;
                    led_data[9:8] <= ALUOp;
                    led_data[7:4] <= ALUControl;
                    led_data[3:2] <= state;
                    led_data[1:0] <= 2'b00;
                end
                default: begin
                    led_data[3:2] <= state;
                end
            endcase
        end
    end

endmodule

//`timescale 1ns / 1ps
//// =========================================================
//// top_lab09.v
//// Top-level FPGA wrapper for RISC-V Control Path Lab 9
////
//// Switch mapping (SW[15:0]):
////   SW[15:9]  = opcode[6:0]    (7 bits)
////   SW[8:6]   = funct3[2:0]    (3 bits)
////   SW[5]     = funct7 (bit 30)(1 bit)
////   SW[4:0]   = unused
////
//// LED mapping (LED[15:0]):
////   LED[15]   = RegWrite
////   LED[14]   = ALUSrc
////   LED[13]   = MemRead
////   LED[12]   = MemWrite
////   LED[11]   = MemtoReg
////   LED[10]   = Branch
////   LED[9:8]  = ALUOp[1:0]
////   LED[7:4]  = ALUControl[3:0]
////   LED[3:2]  = FSM state[1:0]
////   LED[1:0]  = unused
////
//// FSM states:
////   IDLE     (00) - waiting for button press
////   SAMPLE   (01) - latch switch values
////   DISPLAY  (10) - drive LEDs with control signals
////   WAIT_REL (11) - wait for button release
//// =========================================================

//module top_lab09 (
//    input  wire        clk,
//    input  wire        rst,
//    input  wire [15:0] sw,   // 16 FPGA slide switches
//    input  wire        btn,  // push button (step/sample)
//    output wire [15:0] led   // 16 FPGA LEDs
//);

//    // ---- Debounce the push button ----
//    wire btn_clean;
//    debouncer u_deb (
//        .clk   (clk),
//        .pbin  (btn),
//        .pbout (btn_clean)
//    );

//    // ---- Instantiate switches module (Lab 5) ----
//    wire [31:0] sw_readData;
//    switches u_sw (
//        .clk        (clk),
//        .rst        (rst),
//        .btns       (16'b0),
//        .writeData  (32'b0),
//        .writeEnable(1'b0),
//        .readEnable (1'b1),
//        .memAddress (30'b0),
//        .switches   (sw),
//        .readData   (sw_readData)
//    );

//    // ---- Extract fields from switches module output ----
//    wire [6:0] sw_opcode = sw_readData[15:9];
//    wire [2:0] sw_funct3 = sw_readData[8:6];
//    wire       sw_funct7 = sw_readData[5];

//    // ---- Latched instruction fields (set by FSM) ----
//    reg [6:0] opcode_r;
//    reg [2:0] funct3_r;
//    reg       funct7_r;

//    // ---- Control signal wires ----
//    wire       RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch;
//    wire [1:0] ALUOp;
//    wire [3:0] ALUControl;

//    // ---- Instantiate Main Control ----
//    MainControl u_main (
//        .opcode   (opcode_r),
//        .RegWrite (RegWrite),
//        .ALUSrc   (ALUSrc),
//        .MemRead  (MemRead),
//        .MemWrite (MemWrite),
//        .MemtoReg (MemtoReg),
//        .Branch   (Branch),
//        .ALUOp    (ALUOp)
//    );

//    // ---- Instantiate ALU Control ----
//    ALUControl u_alu (
//        .ALUOp      (ALUOp),
//        .funct3     (funct3_r),
//        .funct7     (funct7_r),
//        .ALUControl (ALUControl)
//    );

//    // ---- LED data register ----
//    reg [15:0] led_data;

//    // ---- Instantiate leds module (Lab 5) ----
//    leds u_leds (
//        .clk         (clk),
//        .rst         (rst),
//        .writeData   ({16'b0, led_data}),
//        .writeEnable (1'b1),
//        .readEnable  (1'b0),
//        .memAddress  (30'b0),
//        .readData    (),
//        .leds        (led)
//    );

//    // ---- FSM ----
//    localparam IDLE     = 2'b00;
//    localparam SAMPLE   = 2'b01;
//    localparam DISPLAY  = 2'b10;
//    localparam WAIT_REL = 2'b11;

//    reg [1:0] state, next_state;
//    reg       btn_prev;

//    // State register
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            state    <= IDLE;
//            btn_prev <= 1'b0;
//        end else begin
//            state    <= next_state;
//            btn_prev <= btn_clean;
//        end
//    end

//    // Rising-edge detection
//    wire btn_rise = btn_clean & ~btn_prev;

//    // Next-state logic
//    always @(*) begin
//        next_state = state;
//        case (state)
//            IDLE:     if (btn_rise)   next_state = SAMPLE;
//            SAMPLE:                   next_state = DISPLAY;
//            DISPLAY:  if (!btn_clean) next_state = WAIT_REL;
//            WAIT_REL: if (!btn_clean) next_state = IDLE;
//            default:                  next_state = IDLE;
//        endcase
//    end

//    // Output / datapath logic
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            opcode_r <= 7'b0;
//            funct3_r <= 3'b0;
//            funct7_r <= 1'b0;
//            led_data <= 16'b0;
//        end else begin
//            case (state)
//                SAMPLE: begin
//                    // Latch switch values read from switches module
//                    opcode_r <= sw_opcode;
//                    funct3_r <= sw_funct3;
//                    funct7_r <= sw_funct7;
//                end
//                DISPLAY: begin
//                    // Map control signals to LEDs
//                    led_data[15]  <= RegWrite;
//                    led_data[14]  <= ALUSrc;
//                    led_data[13]  <= MemRead;
//                    led_data[12]  <= MemWrite;
//                    led_data[11]  <= MemtoReg;
//                    led_data[10]  <= Branch;
//                    led_data[9:8] <= ALUOp;
//                    led_data[7:4] <= ALUControl;
//                    led_data[3:2] <= state;
//                    led_data[1:0] <= 2'b00;
//                end
//                default: begin
//                    led_data[3:2] <= state;
//                end
//            endcase
//        end
//    end

//endmodule