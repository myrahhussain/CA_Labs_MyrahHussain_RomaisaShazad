## =========================================================
## constraints_basys3.xdc
## Basys3 FPGA pin constraints for Lab 9 - RISC-V Control Path
## =========================================================

## Clock (100 MHz)
set_property PACKAGE_PIN W5      [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset (BTNC - centre button)
set_property PACKAGE_PIN U18     [get_ports rst]
set_property IOSTANDARD  LVCMOS33 [get_ports rst]

## Step / Sample button (BTNR - right button)
set_property PACKAGE_PIN T17     [get_ports btn]
set_property IOSTANDARD  LVCMOS33 [get_ports btn]

## ---- Slide Switches ----
## SW[15] = opcode[6]   SW[14] = opcode[5]   SW[13] = opcode[4]
## SW[12] = opcode[3]   SW[11] = opcode[2]   SW[10] = opcode[1]
## SW[9]  = opcode[0]
## SW[8]  = funct3[2]   SW[7]  = funct3[1]   SW[6]  = funct3[0]
## SW[5]  = funct7 (bit 30)
## SW[4:0] unused

set_property PACKAGE_PIN V17  [get_ports {sw[0]}]
set_property PACKAGE_PIN V16  [get_ports {sw[1]}]
set_property PACKAGE_PIN W16  [get_ports {sw[2]}]
set_property PACKAGE_PIN W17  [get_ports {sw[3]}]
set_property PACKAGE_PIN W15  [get_ports {sw[4]}]
set_property PACKAGE_PIN V15  [get_ports {sw[5]}]
set_property PACKAGE_PIN W14  [get_ports {sw[6]}]
set_property PACKAGE_PIN W13  [get_ports {sw[7]}]
set_property PACKAGE_PIN V2   [get_ports {sw[8]}]
set_property PACKAGE_PIN T3   [get_ports {sw[9]}]
set_property PACKAGE_PIN T2   [get_ports {sw[10]}]
set_property PACKAGE_PIN R3   [get_ports {sw[11]}]
set_property PACKAGE_PIN W2   [get_ports {sw[12]}]
set_property PACKAGE_PIN U1   [get_ports {sw[13]}]
set_property PACKAGE_PIN T1   [get_ports {sw[14]}]
set_property PACKAGE_PIN R2   [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

## ---- LEDs ----
## LED[15] = RegWrite    LED[14] = ALUSrc
## LED[13] = MemRead     LED[12] = MemWrite
## LED[11] = MemtoReg    LED[10] = Branch
## LED[9:8]= ALUOp       LED[7:4]= ALUControl
## LED[3:2]= FSM state   LED[1:0]= unused

set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property PACKAGE_PIN W18  [get_ports {led[4]}]
set_property PACKAGE_PIN U15  [get_ports {led[5]}]
set_property PACKAGE_PIN U14  [get_ports {led[6]}]
set_property PACKAGE_PIN V14  [get_ports {led[7]}]
set_property PACKAGE_PIN V13  [get_ports {led[8]}]
set_property PACKAGE_PIN V3   [get_ports {led[9]}]
set_property PACKAGE_PIN W3   [get_ports {led[10]}]
set_property PACKAGE_PIN U3   [get_ports {led[11]}]
set_property PACKAGE_PIN P3   [get_ports {led[12]}]
set_property PACKAGE_PIN N3   [get_ports {led[13]}]
set_property PACKAGE_PIN P1   [get_ports {led[14]}]
set_property PACKAGE_PIN L1   [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
