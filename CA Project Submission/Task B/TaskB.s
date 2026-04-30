main:
    addi x2,  x0, 128
    addi x8,  x0, 0      # LED_ADDR = 0 (data memory)
    addi x9,  x0, 512    # SWITCH_ADDR
    addi x11, x0, 8      # threshold
spin:
    lw   x10, 0(x9)
    beq  x10, x0, spin
    bge  x10, x11, big
small:
    jal  x1, doubleIt
    beq  x0, x0, show
big:
    jal  x1, halveIt
    beq  x0, x0, show
show:
    sw   x10, 0(x8)       # store to data memory[0] → LEDs
    beq  x0, x0, spin
doubleIt:
    addi x2, x2, -4
    sw   x1, 0(x2)
    add  x10, x10, x10
    lw   x1, 0(x2)
    addi x2, x2, 4
    jalr x0, 0(x1)
halveIt:
    addi x2, x2, -4
    sw   x1, 0(x2)
    srli x10, x10, 1
    lw   x1, 0(x2)
    addi x2, x2, 4
    jalr x0, 0(x1)