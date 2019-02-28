puts "Info: Running script [info script]"

#FIXME
set DESIGN_NAME "mac4x4"
set VERILOG_NETLIST_FILES "../results/ICC2_files/${DESIGN_NAME}.v"

set SPLIT_CONSTRAINTS_LABEL_NAME split_constraints
set INIT_DP_LABEL_NAME init_dp
set PRE_SHAPING_LABEL_NAME pre_shaping
set PLACE_IO_LABEL_NAME place_io
set SHAPING_LABEL_NAME shaping
set PLACEMENT_LABEL_NAME placement
set CREATE_POWER_LABEL_NAME create_power
set CLOCK_TRUNK_PLANNING_LABEL_NAME clock_trunk_planning
set PLACE_PINS_LABEL_NAME place_pins
set PRE_TIMING_LABEL_NAME pre_timing
set TIMING_ESTIMATION_LABEL_NAME timing_estimation
set BUDGETING_LABEL_NAME budgeting

# Souce common setup
source ../scripts/common/common_setup.tcl

set REPORTS_DIR "../reports"
set RESULTS_DIR "../results"

file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}

#################################################################################
# Search Path Setup
#################################################################################
set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"

###############################################################################
# Library setup
###############################################################################
set REFERENCE_LIBRARY ${MW_REFERENCE_LIB_DIRS}
set DESIGN_LIBRARY    ${DESIGN_NAME}_ICC2_LIB

###############################################################################
# Library setup
###############################################################################
set_app_var target_library ${TARGET_LIBRARY_FILES}
# Enabling the usage of DesignWare minPower Components requires additional DesignWare-LP license
set_app_var synthetic_library "dw_minpower.sldb dw_foundation.sldb"
set_app_var link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"

# Delete the old design library if already exists
if {[file exists $DESIGN_LIBRARY]} {
  puts "Error: ${DESIGN_LIBRARY} already exists"
  exit 1
  # file delete -force ${DESIGN_LIBRARY}
}

create_lib ${DESIGN_LIBRARY} \
  -technology $TECH_FILE \
  -ref_libs $REFERENCE_LIBRARY

###############################################################################
# Read Design
###############################################################################
# read_verilog -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
source ../results/ICC2_files/${DESIGN_NAME}.icc2_script.tcl

puts "Info: Completed script [info script]"
