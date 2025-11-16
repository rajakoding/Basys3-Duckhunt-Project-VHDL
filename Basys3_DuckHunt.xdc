## ===============================================
## BASYS 3 XDC - DUCK HUNT COMPLETE
## ===============================================

## CLOCK (100 MHz)
set_property PACKAGE_PIN W5 [get_ports {CLK100MHZ}]
set_property IOSTANDARD LVCMOS33 [get_ports {CLK100MHZ}]
create_clock -add -name sys_clk_pin -period 10.00 [get_ports {CLK100MHZ}]

## BUTTONS
set_property PACKAGE_PIN U18 [get_ports {BTNC}]  ;# Center Button (RESET)
set_property IOSTANDARD LVCMOS33 [get_ports {BTNC}]

set_property PACKAGE_PIN T18 [get_ports {BTNR}]  ;# Right Button (Manual Shoot)
set_property IOSTANDARD LVCMOS33 [get_ports {BTNR}]

## PS2 MOUSE (USB-HID via Basys3)
## Note: Basys3 requires USB-HID adapter or use PMOD connectors
## Standard PS2 pins on Basys3:
set_property PACKAGE_PIN C17 [get_ports {PS2_CLK}]
set_property IOSTANDARD LVCMOS33 [get_ports {PS2_CLK}]
set_property PULLUP true [get_ports {PS2_CLK}]

set_property PACKAGE_PIN B17 [get_ports {PS2_DATA}]
set_property IOSTANDARD LVCMOS33 [get_ports {PS2_DATA}]
set_property PULLUP true [get_ports {PS2_DATA}]

## LEDs (Score Display - 16 LEDs for score counter)
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]

set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]

set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]

set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]

set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]

set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]

set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]

set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]

set_property PACKAGE_PIN V13 [get_ports {LED[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]

set_property PACKAGE_PIN V3 [get_ports {LED[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]

set_property PACKAGE_PIN W3 [get_ports {LED[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]

set_property PACKAGE_PIN U3 [get_ports {LED[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]

set_property PACKAGE_PIN P3 [get_ports {LED[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]

set_property PACKAGE_PIN N3 [get_ports {LED[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]

set_property PACKAGE_PIN P1 [get_ports {LED[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]

set_property PACKAGE_PIN L1 [get_ports {LED[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]

## VGA OUTPUTS
# Red Channel
set_property PACKAGE_PIN G19 [get_ports {VGA_R[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[0]}]

set_property PACKAGE_PIN H19 [get_ports {VGA_R[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[1]}]

set_property PACKAGE_PIN J19 [get_ports {VGA_R[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[2]}]

set_property PACKAGE_PIN N19 [get_ports {VGA_R[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[3]}]

# Green Channel
set_property PACKAGE_PIN J17 [get_ports {VGA_G[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[0]}]

set_property PACKAGE_PIN H17 [get_ports {VGA_G[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[1]}]

set_property PACKAGE_PIN G17 [get_ports {VGA_G[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[2]}]

set_property PACKAGE_PIN D17 [get_ports {VGA_G[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[3]}]

# Blue Channel
set_property PACKAGE_PIN N18 [get_ports {VGA_B[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[0]}]

set_property PACKAGE_PIN L18 [get_ports {VGA_B[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[1]}]

set_property PACKAGE_PIN K18 [get_ports {VGA_B[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[2]}]

set_property PACKAGE_PIN J18 [get_ports {VGA_B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[3]}]

# Sync Signals
set_property PACKAGE_PIN P19 [get_ports {VGA_HS}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_HS}]

set_property PACKAGE_PIN R19 [get_ports {VGA_VS}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_VS}]

## Timing Constraints for PS2 (if needed)
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports PS2_CLK]
set_input_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports PS2_CLK]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports PS2_DATA]
set_input_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports PS2_DATA]
