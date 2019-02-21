puts "Info: Running script [info script]\n"

# The name of the top-level design
set DESIGN_NAME ""
# Absolute path prefix variable for library/design data
set DESIGN_REF_DATA_PATH [file normalize "../.."]

###############################################################################
# RTL Source variables
###############################################################################
# Set the RTL source files to read
# Note: when autoread is used, this can be a directory as well as files
set RTL_SOURCE_FILES " \
${DESIGN_REF_DATA_PATH}/mac4x4.sv \
"

###############################################################################
# Hierarchical Flow Design Variables
###############################################################################
set HIERARCHICAL_DESIGNS "" ;# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_CELLS   "" ;# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...

###############################################################################
# Library Setup Variables
###############################################################################
source -echo -verbose "../scripts/common/saed32.tcl"

puts "Info: Completed script [info script]\n"
