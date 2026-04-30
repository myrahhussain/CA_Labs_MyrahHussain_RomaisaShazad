# Task B — Demonstrates JAL (J-type), BGE (B-type), LUI (U-type)
#
# Register usage:
#   x2  = stack pointer (SP = 128)
#   x8  = LED address reference (0x100 = 256) - kept for reference only
#   x9  = switch address (0x200 = 512)
#   x10 = switch value / result
#   x11 = threshold (8)
#   x12 = LED address BUILT BY LUI (0x1000 >> 4 = 0x100)
#   x1  = return address
#
# LUI DEMO:
#   lui  x12, 1       -> x12 = 0x00001000
#   srli x12, x12, 4  -> x12 = 0x00000100 = LED address
#   All LED writes use x12 (built from LUI), not x8
#   This proves LUI is working — wrong LUI = wrong address = no LED output
#
# BGE DEMO:
#   bge x10, x11, big
#   if switches >= 8  -> big path  -> halveIt  (divide by 2)
#   if switches <  8  -> small path -> doubleIt (multiply by 2)
#
# JAL DEMO:
#   jal x1, doubleIt  -> jumps to subroutine, saves PC+4 in x1
#   jal x1, halveIt   -> jumps to subroutine, saves PC+4 in x1

.globl main
.text
main:
    addi x2,  x0, 128      # SP = 128
    addi x8,  x0, 256      # LED_ADDR reference = 0x100 (not used for writes)
    addi x9,  x0, 512      # SWITCH_ADDR = 0x200
    addi x11, x0, 8        # threshold = 8

    lui  x12, 1            # LUI: x12 = 0x00001000  <-- NEW INSTRUCTION (U-type)
    srli x12, x12, 4       # x12 = 0x00001000 >> 4 = 0x00000100 = LED address

spin:
    lw   x10, 0(x9)        # read switches
    beq  x10, x0, spin     # if zero keep waiting

    # BGE demo: if switches >= 8 go to big path
    bge  x10, x11, big     # BGE: NEW INSTRUCTION (B-type)

small:
    jal  x1, doubleIt      # JAL: call doubleIt  NEW INSTRUCTION (J-type)
    beq  x0, x0, show      # jump to show

big:
    jal  x1, halveIt       # JAL: call halveIt
    beq  x0, x0, show      # jump to show

show:
    sw   x10, 0(x12)       # store result to LED address (built by LUI)
    beq  x0,  x0, spin     # loop back

# ------------------------------------------------
# doubleIt: x10 = x10 + x10  (multiply by 2)
# ------------------------------------------------
doubleIt:
    add  x10, x10, x10     # double the value
    jalr x0,  0(x1)        # return to caller

# ------------------------------------------------
# halveIt: x10 = x10 >> 1  (divide by 2)
# ------------------------------------------------
halveIt:
    srli x10, x10, 1       # shift right by 1 = divide by 2
    jalr x0,  0(x1)        # return to caller
