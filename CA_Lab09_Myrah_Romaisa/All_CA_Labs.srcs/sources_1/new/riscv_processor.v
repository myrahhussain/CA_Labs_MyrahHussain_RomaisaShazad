`timescale 1ns/1ps

module riscv_processor (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] instruction,
    output wire [31:0] pc,
    input  wire [31:0] readData,
    output wire [31:0] writeData,
    output wire [31:0] memAddress,
    output wire        writeEnable,
    output wire        readEnable
);

    // =========================================================
    // Program Counter
    // =========================================================
    reg [31:0] PC_reg;
    assign pc = PC_reg;

    // =========================================================
    // Register File (x0-x31)
    // =========================================================
    reg [31:0] regfile [0:31];

    // =========================================================
    // Instruction Decode
    // =========================================================
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    // Immediates
    wire [31:0] imm_I = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] imm_S = {{20{instruction[31]}}, instruction[31:25],
                                                instruction[11:7]};
    wire [31:0] imm_B = {{19{instruction[31]}}, instruction[31],
                          instruction[7], instruction[30:25],
                          instruction[11:8], 1'b0};
    wire [31:0] imm_U = {instruction[31:12], 12'b0};
    wire [31:0] imm_J = {{11{instruction[31]}}, instruction[31],
                          instruction[19:12], instruction[20],
                          instruction[30:21], 1'b0};

    // Opcode definitions
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_IMM    = 7'b0010011;
    localparam OP_REG    = 7'b0110011;

    // =========================================================
    // Register Read (x0 always 0)
    // =========================================================
    wire [31:0] rs1_data = (rs1 == 5'd0) ? 32'd0 : regfile[rs1];
    wire [31:0] rs2_data = (rs2 == 5'd0) ? 32'd0 : regfile[rs2];

    // =========================================================
    // ALU
    // =========================================================
    reg  [31:0] alu_result;
    wire [31:0] alu_b = ((opcode == OP_IMM)  ||
                         (opcode == OP_LOAD) ||
                         (opcode == OP_JALR)) ? imm_I : rs2_data;

    always @(*) begin
        alu_result = 32'd0;
        case (opcode)
            OP_LUI:   alu_result = imm_U;
            OP_AUIPC: alu_result = PC_reg + imm_U;
            OP_JAL:   alu_result = PC_reg + 32'd4;
            OP_JALR:  alu_result = PC_reg + 32'd4;
            OP_LOAD:  alu_result = rs1_data + imm_I;
            OP_STORE: alu_result = rs1_data + imm_S;
            OP_IMM: begin
                case (funct3)
                    3'b000: alu_result = rs1_data + alu_b;
                    3'b001: alu_result = rs1_data << alu_b[4:0];
                    3'b010: alu_result = ($signed(rs1_data) < $signed(alu_b)) ? 32'd1 : 32'd0;
                    3'b100: alu_result = rs1_data ^ alu_b;
                    3'b101: alu_result = funct7[5] ?
                                $signed(rs1_data) >>> alu_b[4:0] :
                                rs1_data >> alu_b[4:0];
                    3'b110: alu_result = rs1_data | alu_b;
                    3'b111: alu_result = rs1_data & alu_b;
                    default: alu_result = 32'd0;
                endcase
            end
            OP_REG: begin
                case (funct3)
                    3'b000: alu_result = funct7[5] ?
                                rs1_data - rs2_data :
                                rs1_data + rs2_data;
                    3'b001: alu_result = rs1_data << rs2_data[4:0];
                    3'b010: alu_result = ($signed(rs1_data) < $signed(rs2_data)) ? 32'd1 : 32'd0;
                    3'b100: alu_result = rs1_data ^ rs2_data;
                    3'b101: alu_result = funct7[5] ?
                                $signed(rs1_data) >>> rs2_data[4:0] :
                                rs1_data >> rs2_data[4:0];
                    3'b110: alu_result = rs1_data | rs2_data;
                    3'b111: alu_result = rs1_data & rs2_data;
                    default: alu_result = 32'd0;
                endcase
            end
            default: alu_result = 32'd0;
        endcase
    end

    // =========================================================
    // Branch Logic
    // =========================================================
    reg branch_taken;
    always @(*) begin
        branch_taken = 1'b0;
        if (opcode == OP_BRANCH) begin
            case (funct3)
                3'b000: branch_taken = (rs1_data == rs2_data);
                3'b001: branch_taken = (rs1_data != rs2_data);
                3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));
                3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
                3'b110: branch_taken = (rs1_data < rs2_data);
                3'b111: branch_taken = (rs1_data >= rs2_data);
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // =========================================================
    // Next PC
    // =========================================================
    wire [31:0] pc_plus4  = PC_reg + 32'd4;
    wire [31:0] pc_branch = PC_reg + imm_B;
    wire [31:0] pc_jal    = PC_reg + imm_J;
    wire [31:0] pc_jalr   = (rs1_data + imm_I) & ~32'd1;

    wire [31:0] next_pc =
        (opcode == OP_JAL)                     ? pc_jal    :
        (opcode == OP_JALR)                    ? pc_jalr   :
        (opcode == OP_BRANCH && branch_taken)  ? pc_branch :
                                                  pc_plus4;

    // =========================================================
    // Memory Interface
    // =========================================================
    assign memAddress  = alu_result;
    assign writeData   = rs2_data;
    assign writeEnable = (opcode == OP_STORE);
    assign readEnable  = (opcode == OP_LOAD);

    // =========================================================
    // Sequential Block - explicit register reset, no for-loop
    // =========================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC_reg      <= 32'd0;
            regfile[0]  <= 32'd0;
            regfile[1]  <= 32'd0;
            regfile[2]  <= 32'h00000FFC;  // SP
            regfile[3]  <= 32'd0;
            regfile[4]  <= 32'd0;
            regfile[5]  <= 32'd0;
            regfile[6]  <= 32'd0;
            regfile[7]  <= 32'd0;
            regfile[8]  <= 32'd0;
            regfile[9]  <= 32'd0;
            regfile[10] <= 32'd0;
            regfile[11] <= 32'd0;
            regfile[12] <= 32'd0;
            regfile[13] <= 32'd0;
            regfile[14] <= 32'd0;
            regfile[15] <= 32'd0;
            regfile[16] <= 32'd0;
            regfile[17] <= 32'd0;
            regfile[18] <= 32'd0;
            regfile[19] <= 32'd0;
            regfile[20] <= 32'd0;
            regfile[21] <= 32'd0;
            regfile[22] <= 32'd0;
            regfile[23] <= 32'd0;
            regfile[24] <= 32'd0;
            regfile[25] <= 32'd0;
            regfile[26] <= 32'd0;
            regfile[27] <= 32'd0;
            regfile[28] <= 32'd0;
            regfile[29] <= 32'd0;
            regfile[30] <= 32'd0;
            regfile[31] <= 32'd0;
        end else begin
            PC_reg <= next_pc;

            if (rd != 5'd0) begin
                case (opcode)
                    OP_LUI:   regfile[rd] <= imm_U;
                    OP_AUIPC: regfile[rd] <= PC_reg + imm_U;
                    OP_JAL:   regfile[rd] <= pc_plus4;
                    OP_JALR:  regfile[rd] <= pc_plus4;
                    OP_LOAD:  regfile[rd] <= readData;
                    OP_IMM:   regfile[rd] <= alu_result;
                    OP_REG:   regfile[rd] <= alu_result;
                    default:  ;
                endcase
            end
        end
    end

endmodule