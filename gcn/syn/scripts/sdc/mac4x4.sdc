set sdc_version 2.1

set clock_period 1.000
set setup_margin 0.05
set hold_margin  0.0

# Clock
create_clock -name "clock" -period 1 [get_ports "clock"]

set_input_delay 0.1 -clock "clock" [all_inputs]

set_output_delay 0.1 -clock "clock" [all_outputs]

# Max delay
set_max_delay 10 -from reset
