# Lab 10 FSM Assembly
# Register usage:
#   x2  = stack pointer (SP)
#   x5  = SWITCH_ADDR  = 0x300 = 768
#   x6  = LED_ADDR     = 0x200 = 512
#   x7  = RESET_ADDR   = 0x400 = 1024
#   x10 = captured switch value (argument to RUN_COUNTER)
#   x11 = temp for switch read
#   x12 = current counter value
#   x13 = delay counter
#   x28 = test value
#   x30 = reset register read
#   x1  = return address (ra)

    addi x28, x0,  5      # test value = 5
    addi x2,  x0,  511    # SP = 511
    addi x5,  x0,  768    # SWITCH_ADDR = 0x300
    addi x6,  x0,  512    # LED_ADDR    = 0x200
    addi x7,  x0,  1024   # RESET_ADDR  = 0x400
    sw   x28, 0(x5)       # initial write to switches

IDLE_STATE:
    sw   x0,  0(x6)       # clear LEDs

READ_INPUT:
    lw   x30, 0(x7)       # read reset register
    bne  x30, x0, IDLE_STATE   # if reset pressed, go idle

    lw   x11, 0(x5)       # read switches
    beq  x11, x0, READ_INPUT   # if SW=0, keep waiting

    add  x10, x11, x0    # capture switch value into x10
    jal  x1,  RUN_COUNTER # call countdown 
    beq  x0,  x0, IDLE_STATE  # unconditional jump back to idle

RUN_COUNTER:
    addi x2,  x2,  -8    # allocate stack frame
    sw   x1,  4(x2)      # save return address
    sw   x12, 0(x2)      # save x12
    add  x12, x10, x0    # x12 = counter = captured value

DECREMENT_LOOP:
    sw   x12, 0(x6)      # display counter on LEDs
    beq  x12, x0, EXIT_COUNTER  # if counter=0, exit

    lw   x30, 0(x7)      # check reset
    bne  x30, x0, RESET_ABORT  # if reset, abort

    addi x12, x12, -1    # decrement counter
    addi x13, x0,  3     # delay counter = 3

WAIT_LOOP:
    addi x13, x13, -1    # decrement delay
    lw   x30, 0(x7)      # check reset during delay
    bne  x30, x0, RESET_ABORT
    bne  x13, x0, WAIT_LOOP   # loop until delay done
    beq  x0,  x0, DECREMENT_LOOP  # next count step

RESET_ABORT:
    sw   x0,  0(x6)      # clear LEDs
    lw   x12, 0(x2)      # restore x12
    lw   x1,  4(x2)      # restore return address
    addi x2,  x2,  8     # deallocate stack frame
    j IDLE_STATE         # jump to idle

EXIT_COUNTER:
    sw   x0,  0(x6)      # clear LEDs
    lw   x12, 0(x2)      # restore x12
    lw   x1,  4(x2)      # restore return address
    addi x2,  x2,  8     # deallocate stack frame
    ret