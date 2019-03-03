set sdc_version 2.1

###############################################################################
# Clock
###############################################################################
create_clock [get_ports clock] -name CLOCK -period 2.000

# From PLL uncertainty
set_clock_uncertainty 0.017 [get_clocks CLOCK]

###############################################################################
# Reset
###############################################################################
set_max_delay 2.000 -from reset_n

###############################################################################
# Inputs
###############################################################################
# Driving cell is minimum sized inverter
set_driving_cell -no_design_rule -lib_cell INVX1_HVT -library saed32hvt_ss0p95v125c [all_inputs]
set_input_delay -clock CLOCK -max 0.08 [all_inputs]
set_input_delay -clock CLOCK -min 0.00 [all_inputs]

###############################################################################
# Outputs
###############################################################################
# from "load_of [get_lib_pins saed32hvt_ss0p95v125c/DFFARX2_HVT/D]"
set_load 0.49 [all_outputs]
# Setup/hold time of simple DFFX2
set_output_delay -max 0.02 [all_outputs]
set_output_delay -min 0.00 [all_outputs]

###############################################################################
# Area
###############################################################################
# Attempt to use minimum area
# set_max_area 0.0
