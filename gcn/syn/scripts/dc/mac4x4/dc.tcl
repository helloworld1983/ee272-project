set_app_var sh_continue_on_error "false"

source "../scripts/dc/mac4x4/dc_setup.tcl"

# Design Compiler must be run in topographical mode for SPG flow support
# SPG also requires a license for Design Compiler Graphical
if {![shell_is_in_topographical_mode]} {
  puts "Error: dc_shell must be run in topographical mode for SPG support."
  exit 1
}

###############################################################################
# Pre RTL setup
###############################################################################
source -echo -verbose ../scripts/dc/dc_setup_pre_rtl.tcl

###############################################################################
# Read and link the design
###############################################################################
# Acutually read in the verilog
if {![analyze -format sverilog ${RTL_SOURCE_FILES}]} {
  puts "Error: Could not read RTL source files."
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
# Apply constraints
###############################################################################
read_sdc ${DCRM_SDC_INPUT_FILE}
source -echo -verbose ../scripts/dc/dc_routing.tcl
source -echo -verbose ../scripts/dc/${DESIGN_NAME}/dc_physical_constraints.tcl

# Verify that all the desired physical constraints have been applied
# Add the -pre_route option to include pre-routes in the report
report_physical_constraints > ${REPORTS_DIR}/${DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT}
# report_ignored_layers

###############################################################################
# First compile
###############################################################################
source -echo -verbose ../scripts/dc/dc_create_default_path_groups.tcl
source -echo -verbose ../scripts/dc/dc_pre_first_compile_hplp.tcl

compile_ultra -spg -retime -gate_clock

write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_COMPILE_ULTRA_DDC_OUTPUT_FILE}

###############################################################################
# Incremental compile
###############################################################################
source ../scripts/dc/dc_pre_incr_compile_hplp.tcl
# Creating path groups to reduce TNS
create_auto_path_groups -mode mapped
compile_ultra -incremental -spg -retime -gate_clock
# Remove auto generated path groups
remove_auto_path_groups
# Perform area recovery
optimize_netlist -area

###############################################################################
# Change nameing
###############################################################################
# If this will be a sub-block in a hierarchical design, uniquify with block
# unique names to avoid name collisions when integrating the design at the top
# level
set_app_var uniquify_naming_style "${DESIGN_NAME}_%s_%d"
uniquify -force

change_names -rules verilog -hierarchy

###############################################################################
# Subblock Abstraction
###############################################################################
if {(${DC_BLOCK_ABSTRACTION_DESIGNS} != "") || (${DC_BLOCK_ABSTRACTION_DESIGNS_TIO} != "")} {
  create_block_abstraction
}

###############################################################################
# Write out final design
###############################################################################
# Write out the final design as a DDC file
write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}

# Write out ICC2 files
write_icc2_files -force  -output ${RESULTS_DIR}/${DCRM_FINAL_DESIGN_ICC2}

# Write and close SVF file and make it available for immediate use
set_svf -off

###############################################################################
# Write out extra design data and reports
###############################################################################
source ../scripts/dc/dc_write_extra_design_data.tcl
source ../scripts/dc/dc_generate_reports.tcl

exit
