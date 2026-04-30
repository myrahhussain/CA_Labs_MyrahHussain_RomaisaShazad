.globl main
.text
main:
    addi x2,  x0, 128
    addi x8,  x0, 0      # LED_ADDR = 0 (data memory)
    addi x9,  x0, 512    # SWITCH_ADDR = 0x200
IDLE:
    sw   x0,  0(x8)
READ:
    lw   x11, 0(x9)
    beq  x11, x0, READ
    add  x10, x11, x0
    jal  x1,  RUN_COUNTER
    beq  x0,  x0, IDLE
RUN_COUNTER:
    addi x2,  x2,  -8
    sw   x1,  4(x2)
    sw   x12, 0(x2)
    add  x12, x10, x0
LOOP:
    sw   x12, 0(x8)
    beq  x12, x0, DONE
    addi x12, x12, -1
    beq  x0,  x0, LOOP
DONE:
    sw   x0,  0(x8)
    lw   x12, 0(x2)
    lw   x1,  4(x2)
    addi x2,  x2,  8
    jalr x0,  0(x1)