puts "Info: Running script [info script]"

# The name of the top-level design
set DESIGN_NAME "execute"
# Absolute path prefix variable for library/design data
set DESIGN_REF_DATA_PATH [file normalize "../.."]
# Absolute path prefix variable for scripts
set DESIGN_SCRIPT_PATH [file normalize ".."]

###############################################################################
# Hierarchical Flow Design Variables
###############################################################################
# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_DESIGNS "mac4x4"

# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...
set HIERARCHICAL_CELLS   ""

###############################################################################
# RTL Source variables
###############################################################################
# Set the RTL source files to read
# Note: when autoread is used, this can be a directory as well as files
set RTL_SOURCE_FILES " \
${DESIGN_REF_DATA_PATH}/execute.sv \
${DESIGN_REF_DATA_PATH}/reductionbuffer.sv \
${DESIGN_REF_DATA_PATH}/mac4x4.sv \
${DESIGN_REF_DATA_PATH}/mac16x16.sv \
${DESIGN_REF_DATA_PATH}/lib/dp/KW_dblbuf.sv \
${DESIGN_REF_DATA_PATH}/lib/dp/KW_dblbuf_cntl.sv \
${DESIGN_REF_DATA_PATH}/lib/dp/KW_pipe_reg.sv \
${DESIGN_REF_DATA_PATH}/lib/sram/KW_ram_1rws_sram.sv \
${DESIGN_REF_DATA_PATH}/lib/sram/KW_ram_1rws_dff.sv \
"

###############################################################################
# Library Setup Variables
###############################################################################
source "${DESIGN_SCRIPT_PATH}/scripts/common/saed32.tcl"

################################################################################
# Don't Use File
################################################################################
# Tcl file to prevent Synopsys from considering irrelevent or unneeded library
# components.
set LIBRARY_DONT_USE_FILE                   "${DESIGN_SCRIPT_PATH}/scripts/common/dont_use.tcl"
set LIBRARY_DONT_USE_PRE_COMPILE_LIST       ""
set LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST  ""

################################################################################
# Multi-Voltage Variables
################################################################################
# Use as few or as many of the following definitions as needed by your design.
set PD1              ""           ;# Name of power domain/voltage area  1
set PD1_CELLS        ""           ;# Instances to include in power domain/voltage area 1
set VA1_COORDINATES  {}           ;# Coordinates for voltage area 1
set MW_POWER_NET1    "VDD1"       ;# Power net for voltage area 1
set MW_POWER_PORT1   "VDD"        ;# Power port for voltage area 1

set PD2              ""           ;# Name of power domain/voltage area  2
set PD2_CELLS        ""           ;# Instances to include in power domain/voltage area 2
set VA2_COORDINATES  {}           ;# Coordinates for voltage area 2
set MW_POWER_NET2    "VDD2"       ;# Power net for voltage area 2
set MW_POWER_PORT2   "VDD"        ;# Power port for voltage area 2

set PD3              ""           ;# Name of power domain/voltage area  3
set PD3_CELLS        ""           ;# Instances to include in power domain/voltage area 3
set VA3_COORDINATES  {}           ;# Coordinates for voltage area 3
set MW_POWER_NET3    "VDD3"       ;# Power net for voltage area 3
set MW_POWER_PORT3   "VDD"        ;# Power port for voltage area 3

set PD4              ""           ;# Name of power domain/voltage area  4
set PD4_CELLS        ""           ;# Instances to include in power domain/voltage area 4
set VA4_COORDINATES  {}           ;# Coordinates for voltage area 4
set MW_POWER_NET4    "VDD4"       ;# Power net for voltage area 4
set MW_POWER_PORT4   "VDD"        ;# Power port for voltage area 4

puts "Info: Completed script [info script]"
