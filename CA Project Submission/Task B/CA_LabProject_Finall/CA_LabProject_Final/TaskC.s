# Task C — Fibonacci Sequence with Stack-Based Procedure Call
#
# Register usage:
#   x2  = stack pointer (starts at 252, top of data memory)
#   x8  = LED address (0x100 = 256)
#   x5  = a (current Fibonacci term)
#   x6  = b (next Fibonacci term)
#   x10 = argument/return: old_b
#   x11 = argument/return: new_fib
#   x7  = temp for addition
#   x1  = return address (ra)
#
# Fibonacci sequence: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55...
# Each term displayed on LEDs
# Stack used to save/restore return address in procedure call

.globl main
.text
main:
    addi x2, x0, 252    # SP = 252 (top of data memory)
    addi x8, x0, 256    # LED_ADDR = 0x100
    addi x5, x0, 1      # a = 1 (first term)
    addi x6, x0, 1      # b = 1 (second term)

loop:
    sw   x5, 0(x8)      # display a on LEDs
    add  x10, x0, x5    # pass a as argument (x10 = a)
    add  x11, x0, x6    # pass b as argument (x11 = b)
    jal  x1, calc_fib   # call calc_fib, save return address in x1
    add  x5, x0, x10    # a = old_b (returned in x10)
    add  x6, x0, x11    # b = new_fib (returned in x11)
    jal  x0, loop       # infinite loop (j loop)

calc_fib:
    addi x2, x2, -4     # allocate stack frame (push)
    sw   x1, 0(x2)      # save return address to stack
    add  x7, x10, x11   # x7 = a + b (new Fibonacci number)
    add  x10, x0, x11   # return x10 = old_b
    add  x11, x0, x7    # return x11 = new_fib
    lw   x1, 0(x2)      # restore return address from stack
    addi x2, x2, 4      # deallocate stack frame (pop)
    jalr x0, 0(x1)      # return to caller