source "../scripts/dc/dc_setup.tcl"

# Design Compiler must be run in topographical mode for SPG flow support
# SPG also requires a license for Design Compiler Graphical
if {![shell_is_in_topographical_mode]} {
  puts "Error: dc_shell must be run in topographical mode for SPG support."
  exit 1
}

# If we have a pre-compile don't use list, source it here
if {[file exists [which ${LIBRARY_DONT_USE_PRE_COMPILE_LIST}]]} {
  puts "Info: Sourcing script file [which ${LIBRARY_DONT_USE_PRE_COMPILE_LIST}]\n"
  source -echo -verbose $LIBRARY_DONT_USE_PRE_COMPILE_LIST
}

################################################################################
# Setup Formality Verification
################################################################################
# For designs that don't have tight QoR constraints and don't have register retiming,
# you can use the following variable to enable the highest productivity single pass flow.
# This flow modifies the optimizations to make verification easier.
# This variable setting should be applied prior to reading in the RTL for the design.

# set_app_var simplified_verification_mode true

# Define the verification setup file for Formality
set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

###############################################################################
# Setup SAIF Name Mapping Database
###############################################################################
# Include an RTL SAIF for better power optimization and analysis.
# saif_map should be issued prior to RTL elaboration to create a name mapping
# database for better annotation.
saif_map -start

###############################################################################
# Read and link the design
###############################################################################
# Define the folder to use for temporary files
define_design_lib WORK -path ./WORK

# Helps verification resolve differences between DC and FM
set_app_var hdlin_enable_hier_map true

# Set the filenames we recognize for each RTL type
# Only needed for the "-autoread" option of analyze
# set_app_var hdlin_autoread_verilog_extensions    ".v"
# set_app_var hdlin_autoread_sverilog_extensions   ".sv .sverilog"
# set_app_var hdlin_autoread_vhdl_extensions       ".vhd .vhdl"

# Acutually read in the verilog
if {![analyze -format sverilog ${RTL_SOURCE_FILES}]} {
  puts "Error: Could not read RTL source files"
  exit 1
}

# Elaborate the top level design
elaborate ${DESIGN_NAME}
current_design ${DESIGN_NAME}

# Set the verification top level
set_verification_top

# Write out the fully elaborated design
write -hierarchy -format ddc -output ${RESULTS_DIR}/${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}

# Link the design
link

###############################################################################
# Create the timing constraints
###############################################################################
# Our timing constraints are in a SDC file
read_sdc ${DCRM_SDC_INPUT_FILE}

###############################################################################
# Create Default Path Groups
#
# Separating these paths can help improve optimization.
# Remove these path group settings if user path groups have already been defined.
###############################################################################
# Uncomment this if we have multiple active senarios
# set current_scenario_saved [current_scenario]
# foreach scenario [all_active_scenarios] {
#   current_scenario ${scenario}
#   set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
#   group_path -name REGOUT -to [all_outputs] 
#   group_path -name REGIN -from [remove_from_collection [all_inputs] ${ports_clock_root}] 
#   group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] ${ports_clock_root}] -to [all_outputs]
# }
# current_scenario ${current_scenario_saved}
set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
group_path -name REGOUT -to [all_outputs] 
group_path -name REGIN -from [remove_from_collection [all_inputs] ${ports_clock_root}] 
group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] ${ports_clock_root}] -to [all_outputs]

###############################################################################
# Apply Physical Design Constraints
###############################################################################
# Specify ignored layers for routing to improve correlation
# Use the same ignored layers that will be used during place and route
if { ${MIN_ROUTING_LAYER} != ""} {
  set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
}
if { ${MAX_ROUTING_LAYER} != ""} {
  set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
}

report_ignored_layers

# Optional: Floorplan information can be read in here if available.
# read_floorplan ${DCRM_DCT_FLOORPLAN_INPUT_FILE}.objects
# read_floorplan ${DCRM_DCT_FLOORPLAN_INPUT_FILE}

# Verify that all the desired physical constraints have been applied
# Add the -pre_route option to include pre-routes in the report
report_physical_constraints > ${REPORTS_DIR}/${DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT}

#################################################################################
# Apply Additional Optimization Constraints
#################################################################################
# Prevent assignment statements in the Verilog netlist.
set_fix_multiple_port_nets -all -buffer_constants

###############################################################################
# Setup for first compile
###############################################################################
# Enable support for via RC estimation to improve timing correlation with 
# IC Compiler
set_app_var spg_enable_via_resistance_support true

# The following variable, when set to true, runs additional optimizations to
# improve the timing of the design at the cost of additional run time.
set_app_var compile_timing_high_effort true

# The following variable enables a mode of coarse placement in which cells are not distributed  
# evenly  across the surface but are allowed to clump together for better QoR     
set_app_var placer_max_cell_density_threshold 0.75        

# Set the maximum utilization to 0.9 in congestion options 
set_congestion_options -max_util 0.90

# The following variable, when set to true, enables very high effort
# optimization to fix total negative slack.
# Setting following variable to true may affect run time
set_app_var psynopt_tns_high_effort true

# Use the following variable to enable the physically aware clock gating 
set_app_var power_cg_physically_aware_cg true

#The following variable helps to reduce the total negative slack of the design
set_app_var placer_tns_driven true

# Enable low power placement.  
# Low power placement affects the placement of cells, pulls them closer together, 
# on nets with high switching activity to reduce the overall dynamic power of your design.  
# set_app_var power_low_power_placement true

# In MCMM flow use set_scenario_options -dynamic_power true 
# set_dynamic_optimization true

#################################################################################
# Check for Design Problems 
#################################################################################
# Check design for consistancy
check_design -summary
check_design > ${REPORTS_DIR}/${DCRM_CHECK_DESIGN_REPORT}

# The analyze_datapath_extraction command can help you to analyze why certain data 
# paths are no extracted, uncomment the following line to report analyisis.
# analyze_datapath_extraction > ${REPORTS_DIR}/${DCRM_ANALYZE_DATAPATH_EXTRACTION_REPORT}

###############################################################################
# First compile
###############################################################################
compile_ultra -spg -retime -gate_clock

###############################################################################
# Setup for incremental compile
###############################################################################
# Creating path groups to reduce TNS
create_auto_path_groups -mode mapped

# Enable congestion-driven  placement  in incremental compile to improve congestion
set_app_var spg_congestion_placement_in_incremental_compile true

# If we have an incremental don't use list, source it here
if {[file exists [which ${LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST}]]} {
  puts "Info: Sourcing script file [which ${LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST}]\n"
  source -echo -verbose $LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST
}

###############################################################################
# Incremental compile
###############################################################################
compile_ultra -incramental -spg -retime -gate_clock

# Remove paths created by create_auto_path_groups
remove_auto_path_groups

# Performs monotonic gate transformations that reduce area but do not increase
# leakage or timing
optimize_netlist -area

###############################################################################
# Write out final design
###############################################################################
# If this will be a sub-block in a hierarchical design, uniquify with block
# unique names to avoid name collisions when integrating the design at the top
# level
set_app_var uniquify_naming_style "${DESIGN_NAME}_%s_%d"
uniquify -force

change_names -rules verilog -hierarchy

# Write out ICC2 files
write_icc2_files -force  -output ${RESULTS_DIR}/${DCRM_FINAL_DESIGN_ICC2}

# Write out the final design as a DDC file
write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}

# Write and close SVF file and make it available for immediate use
set_svf -off

###############################################################################
# Write out extra design data
###############################################################################
# Note: A secondary floorplan file $DCT_FINAL_FLOORPLAN_OUTPUT_FILE}.objects
# might also be written to capture physical-only objects in the design.
# This file should be read in before reading the main floorplan file.
write_floorplan -all ${RESULTS_DIR}/${DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE}

# Do not write out net RC info into SDC
set_app_var write_sdc_output_lumped_net_capacitance false
set_app_var write_sdc_output_net_resistance false

# Note: if you have more than one senario, loop over them here
# set all_active_scenario_saved [all_active_scenarios]
# set current_scenario_saved [current_scenario]
# set_active_scenarios -all
# foreach scenario [all_active_scenarios] {
#   current_scenario ${scenario}
#   write_parasitics
#   write_sdf
#   write_sdc
#}
# current_scenario ${current_scenario_saved}
# set_active_scenarios ${all_active_scenario_saved}

# Write parasitics data from Design Compiler Topographical placement for
# static timing analysis
write_parasitics -output ${RESULTS_DIR}/${DCRM_DCT_FINAL_SPEF_OUTPUT_FILE}

# Write SDF backannotation data from Design Compiler Topographical placement
# for static timing analysis
write_sdf ${RESULTS_DIR}/${DCRM_DCT_FINAL_SDF_OUTPUT_FILE}

# Write timing constraints
write_sdc -nosplit ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}

# Write the map between pre and post sythesis names for timing analysis
saif_map -type ptpx -write_map ${RESULTS_DIR}/${DESIGN_NAME}.mapped.SAIF.namemap

###############################################################################
# Write out final reports
###############################################################################
report_qor > ${REPORTS_DIR}/${DCRM_FINAL_QOR_REPORT}

# Timing
report_timing -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_TIMING_REPORT}

# Area
report_area -physical -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT}
report_area -designware  > ${REPORTS_DIR}/${DCRM_FINAL_DESIGNWARE_AREA_REPORT}
report_resources -hierarchy > ${REPORTS_DIR}/${DCRM_FINAL_RESOURCES_REPORT}

# Power
# Use SAIF file for power analysis
# set current_scenario_saved [current_scenario]
# foreach scenario [all_active_scenarios] {
#   current_scenario ${scenario}
#   read_saif -auto_map_names -input ${DESIGN_NAME}.${scenario}.saif -instance < DESIGN_INSTANCE > -verbose
# }
# current_scenario ${current_scenario_saved}
report_power -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_POWER_REPORT}
report_clock_gating -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}
report_threshold_voltage_group -nosplit > ${REPORTS_DIR}/${DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT}

# Congestion
report_congestion > ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_REPORT}
