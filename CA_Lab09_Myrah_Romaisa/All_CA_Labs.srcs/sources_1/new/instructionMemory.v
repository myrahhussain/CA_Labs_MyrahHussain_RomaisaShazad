

//============FOR SIMULATION==========================//
`timescale 1ns/1ps
// ============================================================
// instructionMemory_sim.v
// SIMULATION ONLY - delay loop = 10 cycles instead of 333,000
// Logic is identical to instructionMemory.v
// In Vivado: set this file as Simulation only (not synthesis)
// ============================================================
module instructionMemory #(
    parameter OPERAND_LENGTH = 31
)(
    input  [OPERAND_LENGTH:0] instAddress,
    output reg [31:0]         instruction
);

    reg [7:0] memory [0:255];

    initial begin
        // _start: PC=0
        // lui s0, 0xC0000
        memory[0]=8'h37; memory[1]=8'h04; memory[2]=8'h00; memory[3]=8'hC0;
        // addi s0, s0, 4
        memory[4]=8'h13; memory[5]=8'h04; memory[6]=8'h44; memory[7]=8'h00;
        // lui s1, 0xC0000
        memory[8]=8'hB7; memory[9]=8'h04; memory[10]=8'h00; memory[11]=8'hC0;
        // lui s2, 0xC0000
        memory[12]=8'h37; memory[13]=8'h09; memory[14]=8'h00; memory[15]=8'hC0;
        // addi s2, s2, 8
        memory[16]=8'h13; memory[17]=8'h09; memory[18]=8'h89; memory[19]=8'h00;

        // input_wait: PC=20
        // sw zero, 0(s1)
        memory[20]=8'h23; memory[21]=8'hA0; memory[22]=8'h04; memory[23]=8'h00;
        // lw t0, 0(s2)
        memory[24]=8'h83; memory[25]=8'h22; memory[26]=8'h09; memory[27]=8'h00;
        // andi t0, t0, 1
        memory[28]=8'h93; memory[29]=8'h82; memory[30]=8'h12; memory[31]=8'h00;

        // poll_loop: PC=32
        // lw t0, 0(s0)
        memory[32]=8'h83; memory[33]=8'h22; memory[34]=8'h04; memory[35]=8'h00;
        // andi t0, t0, -1
        memory[36]=8'h93; memory[37]=8'hF2; memory[38]=8'hF2; memory[39]=8'hFF;
        // beq t0, zero, poll_loop (offset=-12)
        memory[40]=8'hE3; memory[41]=8'h8C; memory[42]=8'h02; memory[43]=8'hFE;

        // PC=44: mv a0, t0
        memory[44]=8'h13; memory[45]=8'h85; memory[46]=8'h02; memory[47]=8'h00;
        // sw a0, 0(s1)
        memory[48]=8'h23; memory[49]=8'hA0; memory[50]=8'hAA; memory[51]=8'h00;
        // addi sp, sp, -4
        memory[52]=8'h13; memory[53]=8'h01; memory[54]=8'hC1; memory[55]=8'hFF;
        // sw ra, 0(sp)
        memory[56]=8'h23; memory[57]=8'h20; memory[58]=8'h11; memory[59]=8'h00;
        // jal ra, countdown (PC=60 ? PC=76, offset=+16)
        memory[60]=8'hEF; memory[61]=8'h00; memory[62]=8'h00; memory[63]=8'h01;
        // lw ra, 0(sp)
        memory[64]=8'h83; memory[65]=8'h20; memory[66]=8'h01; memory[67]=8'h00;
        // addi sp, sp, 4
        memory[68]=8'h13; memory[69]=8'h01; memory[70]=8'h41; memory[71]=8'h00;
        // j input_wait (PC=72 ? PC=20, offset=-52)
        memory[72]=8'h6F; memory[73]=8'hF0; memory[74]=8'hDF; memory[75]=8'hFC;

        // countdown: PC=76
        // addi sp, sp, -8
        memory[76]=8'h13; memory[77]=8'h01; memory[78]=8'h81; memory[79]=8'hFF;
        // sw ra, 4(sp)
        memory[80]=8'h23; memory[81]=8'h22; memory[82]=8'h11; memory[83]=8'h00;
        // sw s3, 0(sp)
        memory[84]=8'h23; memory[85]=8'h20; memory[86]=8'h31; memory[87]=8'h01;
        // mv s3, a0
        memory[88]=8'h93; memory[89]=8'h09; memory[90]=8'h05; memory[91]=8'h00;

        // count_loop: PC=92
        // beq s3, zero, count_done (PC=136, offset=+44)
        memory[92]=8'h63; memory[93]=8'h86; memory[94]=8'hC9; memory[95]=8'h02;
        // lw t0, 0(s2)
        memory[96]=8'h83; memory[97]=8'h22; memory[98]=8'h09; memory[99]=8'h00;
        // andi t0, t0, 1
        memory[100]=8'h93; memory[101]=8'h82; memory[102]=8'h12; memory[103]=8'h00;
        // bne t0, zero, do_reset (PC=156, offset=+52)
        memory[104]=8'h63; memory[105]=8'h8C; memory[106]=8'h02; memory[107]=8'h03;
        // sw s3, 0(s1)
        memory[108]=8'h23; memory[109]=8'hA0; memory[110]=8'h34; memory[111]=8'h01;

        // ============================================================
        // SIMULATION DELAY: addi t1, zero, 10  (only 10 iterations)
        // Real version uses lui+addi for ~333,000 iterations
        // addi t1, zero, 10 ? 0x00A00313
        // ============================================================
        memory[112]=8'h13; memory[113]=8'h03; memory[114]=8'hA0; memory[115]=8'h00;
        // nop (addi zero, zero, 0) to keep PC alignment same as real version
        memory[116]=8'h13; memory[117]=8'h00; memory[118]=8'h00; memory[119]=8'h00;

        // delay_loop: PC=120
        // addi t1, t1, -1
        memory[120]=8'h13; memory[121]=8'h03; memory[122]=8'hF3; memory[123]=8'hFF;
        // bne t1, zero, delay_loop (offset=-4)
        memory[124]=8'hE3; memory[125]=8'h1E; memory[126]=8'h03; memory[127]=8'hFE;

        // addi s3, s3, -1
        memory[128]=8'h93; memory[129]=8'h89; memory[130]=8'hF9; memory[131]=8'hFF;
        // j count_loop (PC=132 ? PC=92, offset=-40)
        memory[132]=8'h6F; memory[133]=8'hF0; memory[134]=8'h9F; memory[135]=8'hFD;

        // count_done: PC=136
        // sw zero, 0(s1)
        memory[136]=8'h23; memory[137]=8'hA0; memory[138]=8'h04; memory[139]=8'h00;
        // lw s3, 0(sp)
        memory[140]=8'h83; memory[141]=8'h29; memory[142]=8'h01; memory[143]=8'h00;
        // lw ra, 4(sp)
        memory[144]=8'h83; memory[145]=8'h20; memory[146]=8'h41; memory[147]=8'h00;
        // addi sp, sp, 8
        memory[148]=8'h13; memory[149]=8'h01; memory[150]=8'h81; memory[151]=8'h00;
        // ret
        memory[152]=8'h67; memory[153]=8'h80; memory[154]=8'h00; memory[155]=8'h00;

        // do_reset: PC=156
        // sw zero, 0(s1)
        memory[156]=8'h23; memory[157]=8'hA0; memory[158]=8'h04; memory[159]=8'h00;
        // lw s3, 0(sp)
        memory[160]=8'h83; memory[161]=8'h29; memory[162]=8'h01; memory[163]=8'h00;
        // lw ra, 4(sp)
        memory[164]=8'h83; memory[165]=8'h20; memory[166]=8'h41; memory[167]=8'h00;
        // addi sp, sp, 8
        memory[168]=8'h13; memory[169]=8'h01; memory[170]=8'h81; memory[171]=8'h00;
        // ret
        memory[172]=8'h67; memory[173]=8'h80; memory[174]=8'h00; memory[175]=8'h00;
    end

    always @(*) begin
        instruction = {
            memory[instAddress + 3],
            memory[instAddress + 2],
            memory[instAddress + 1],
            memory[instAddress + 0]
        };
    end

endmodule










//`timescale 1ns/1ps

//module instructionMemory #(
//    parameter OPERAND_LENGTH = 31
//)(
//    input  [OPERAND_LENGTH:0] instAddress,
//    output reg [31:0]         instruction
//);

//    reg [7:0] memory [0:255];

//    initial begin
//        // _start: PC=0
//        // lui s0, 0xC0000  (s0 = 0xC0000000, switches base)
//        memory[0]=8'h37; memory[1]=8'h04; memory[2]=8'h00; memory[3]=8'hC0;
//        // addi s0, s0, 4   (s0 = 0xC0000004 = switches)
//        memory[4]=8'h13; memory[5]=8'h04; memory[6]=8'h44; memory[7]=8'h00;
//        // lui s1, 0xC0000  (s1 = 0xC0000000 = LEDs)
//        memory[8]=8'hB7; memory[9]=8'h04; memory[10]=8'h00; memory[11]=8'hC0;
//        // lui s2, 0xC0000  (s2 = 0xC0000000, reset base)
//        memory[12]=8'h37; memory[13]=8'h09; memory[14]=8'h00; memory[15]=8'hC0;
//        // addi s2, s2, 8   (s2 = 0xC0000008 = reset reg)
//        memory[16]=8'h13; memory[17]=8'h09; memory[18]=8'h89; memory[19]=8'h00;

//        // input_wait: PC=20
//        // sw zero, 0(s1)   - clear LEDs
//        memory[20]=8'h23; memory[21]=8'hA0; memory[22]=8'h04; memory[23]=8'h00;
//        // lw t0, 0(s2)     - read reset
//        memory[24]=8'h83; memory[25]=8'h22; memory[26]=8'h09; memory[27]=8'h00;
//        // andi t0, t0, 1
//        memory[28]=8'h93; memory[29]=8'h82; memory[30]=8'h12; memory[31]=8'h00;

//        // poll_loop: PC=32
//        // lw t0, 0(s0)     - read switches
//        memory[32]=8'h83; memory[33]=8'h22; memory[34]=8'h04; memory[35]=8'h00;
//        // andi t0, t0, -1  - mask (0xFFF sign-extended)
//        memory[36]=8'h93; memory[37]=8'hF2; memory[38]=8'hF2; memory[39]=8'hFF;
//        // beq t0, zero, poll_loop  (offset = -12)
//        memory[40]=8'hE3; memory[41]=8'h8C; memory[42]=8'h02; memory[43]=8'hFE;

//        // PC=44: mv a0, t0
//        memory[44]=8'h13; memory[45]=8'h85; memory[46]=8'h02; memory[47]=8'h00;
//        // sw a0, 0(s1)     - show on LEDs immediately
//        memory[48]=8'h23; memory[49]=8'hA0; memory[50]=8'hAA; memory[51]=8'h00;
//        // addi sp, sp, -4
//        memory[52]=8'h13; memory[53]=8'h01; memory[54]=8'hC1; memory[55]=8'hFF;
//        // sw ra, 0(sp)
//        memory[56]=8'h23; memory[57]=8'h20; memory[58]=8'h11; memory[59]=8'h00;
//        // jal ra, countdown  (PC=60, countdown at PC=76, offset=+16)
//        memory[60]=8'hEF; memory[61]=8'h00; memory[62]=8'h00; memory[63]=8'h01;
//        // lw ra, 0(sp)
//        memory[64]=8'h83; memory[65]=8'h20; memory[66]=8'h01; memory[67]=8'h00;
//        // addi sp, sp, 4
//        memory[68]=8'h13; memory[69]=8'h01; memory[70]=8'h41; memory[71]=8'h00;
//        // j input_wait  (PC=72, input_wait at PC=20, offset=-52)
//        memory[72]=8'h6F; memory[73]=8'hF0; memory[74]=8'hDF; memory[75]=8'hFC;

//        // countdown subroutine: PC=76
//        // addi sp, sp, -8
//        memory[76]=8'h13; memory[77]=8'h01; memory[78]=8'h81; memory[79]=8'hFF;
//        // sw ra, 4(sp)
//        memory[80]=8'h23; memory[81]=8'h22; memory[82]=8'h11; memory[83]=8'h00;
//        // sw s3, 0(sp)
//        memory[84]=8'h23; memory[85]=8'h20; memory[86]=8'h31; memory[87]=8'h01;
//        // mv s3, a0  (addi s3, a0, 0)
//        memory[88]=8'h93; memory[89]=8'h09; memory[90]=8'h05; memory[91]=8'h00;

//        // count_loop: PC=92
//        // beq s3, zero, count_done  (count_done at PC=136, offset=+44)
//        memory[92]=8'h63; memory[93]=8'h86; memory[94]=8'hC9; memory[95]=8'h02;
//        // lw t0, 0(s2)   - check reset
//        memory[96]=8'h83; memory[97]=8'h22; memory[98]=8'h09; memory[99]=8'h00;
//        // andi t0, t0, 1
//        memory[100]=8'h93; memory[101]=8'h82; memory[102]=8'h12; memory[103]=8'h00;
//        // bne t0, zero, do_reset  (do_reset at PC=156, offset=+52... adjusted below)
//        memory[104]=8'h63; memory[105]=8'h8C; memory[106]=8'h02; memory[107]=8'h03;
//        // sw s3, 0(s1)   - update LEDs
//        memory[108]=8'h23; memory[109]=8'hA0; memory[110]=8'h34; memory[111]=8'h01;

//        // delay setup: lui t1, 0x51
//        memory[112]=8'h37; memory[113]=8'h13; memory[114]=8'h05; memory[115]=8'h00;
//        // addi t1, t1, 0x1FF
//        memory[116]=8'h13; memory[117]=8'h03; memory[118]=8'hF3; memory[119]=8'h1F;

//        // delay_loop: PC=120
//        // addi t1, t1, -1
//        memory[120]=8'h13; memory[121]=8'h03; memory[122]=8'hF3; memory[123]=8'hFF;
//        // bne t1, zero, delay_loop  (offset=-4)
//        memory[124]=8'hE3; memory[125]=8'h1E; memory[126]=8'h03; memory[127]=8'hFE;

//        // addi s3, s3, -1
//        memory[128]=8'h93; memory[129]=8'h89; memory[130]=8'hF9; memory[131]=8'hFF;
//        // j count_loop  (PC=132, count_loop=92, offset=-40)
//        memory[132]=8'h6F; memory[133]=8'hF0; memory[134]=8'h9F; memory[135]=8'hFD;

//        // count_done: PC=136
//        // sw zero, 0(s1)
//        memory[136]=8'h23; memory[137]=8'hA0; memory[138]=8'h04; memory[139]=8'h00;
//        // lw s3, 0(sp)
//        memory[140]=8'h83; memory[141]=8'h29; memory[142]=8'h01; memory[143]=8'h00;
//        // lw ra, 4(sp)
//        memory[144]=8'h83; memory[145]=8'h20; memory[146]=8'h41; memory[147]=8'h00;
//        // addi sp, sp, 8
//        memory[148]=8'h13; memory[149]=8'h01; memory[150]=8'h81; memory[151]=8'h00;
//        // ret
//        memory[152]=8'h67; memory[153]=8'h80; memory[154]=8'h00; memory[155]=8'h00;

//        // do_reset: PC=156
//        // sw zero, 0(s1)
//        memory[156]=8'h23; memory[157]=8'hA0; memory[158]=8'h04; memory[159]=8'h00;
//        // lw s3, 0(sp)
//        memory[160]=8'h83; memory[161]=8'h29; memory[162]=8'h01; memory[163]=8'h00;
//        // lw ra, 4(sp)
//        memory[164]=8'h83; memory[165]=8'h20; memory[166]=8'h41; memory[167]=8'h00;
//        // addi sp, sp, 8
//        memory[168]=8'h13; memory[169]=8'h01; memory[170]=8'h81; memory[171]=8'h00;
//        // ret
//        memory[172]=8'h67; memory[173]=8'h80; memory[174]=8'h00; memory[175]=8'h00;
//    end

//    always @(*) begin
//        instruction = {
//            memory[instAddress + 3],
//            memory[instAddress + 2],
//            memory[instAddress + 1],
//            memory[instAddress + 0]
//        };
//    end

//endmodule