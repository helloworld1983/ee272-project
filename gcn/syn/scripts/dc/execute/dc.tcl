set_app_var sh_continue_on_error "false"

source "../scripts/dc/execute/dc_setup.tcl"

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
if { ${ICC_BLOCK_ABSTRACTION_DESIGNS} != ""} {
  set_top_implementation_options -block_references ${ICC_BLOCK_ABSTRACTION_DESIGNS}
}
if { ${DC_BLOCK_ABSTRACTION_DESIGNS} != ""} {
  set_top_implementation_options -block_references ${DC_BLOCK_ABSTRACTION_DESIGNS}
}
# Enable the -optimize_block_interface option for DC block abstraction with 
# transparent interface optimization.
# Note: If interface optimization is enabled the updated DC blocks must be written out
# after optimization.
if { ${DC_BLOCK_ABSTRACTION_DESIGNS_TIO} != ""} {
  set_top_implementation_options -block_references ${DC_BLOCK_ABSTRACTION_DESIGNS_TIO} -optimize_block_interface true
}

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

# Remove the RTL version of the hierarchical blocks in case they were read in
set HIER_DESIGNS "${DDC_HIER_DESIGNS} ${DC_BLOCK_ABSTRACTION_DESIGNS} ${DC_BLOCK_ABSTRACTION_DESIGNS_TIO} ${ICC_BLOCK_ABSTRACTION_DESIGNS}"
foreach design $HIER_DESIGNS {
  if {[filter [get_designs -quiet *] "@hdl_template == $design"] != "" } {
    remove_design -hierarchy [filter [get_designs -quiet *] "@hdl_template == $design"]
  }
}

# Write out the elaborated design without the hierarchical references
write -hierarchy -format ddc -output ${RESULTS_DIR}/${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}

#################################################################################
# Load Hierarchical Designs
#################################################################################
# Read in compiled hierarchical blocks
# For topographical mode top-level synthesis all physical blocks are required to
# be compiled in topographical mode.
foreach design ${DDC_HIER_DESIGNS} {
  read_ddc ../results/${design}.mapped.ddc
}

foreach design ${DC_BLOCK_ABSTRACTION_DESIGNS} {
  read_ddc ../results/${design}.mapped.ddc
}

foreach design ${DC_BLOCK_ABSTRACTION_DESIGNS_TIO} {
  read_ddc ../results/${design}.mapped.ddc
}

# Enable the linker to allow a period (.) as an alternative to an underscore (_) 
# when doing port name matching for the hierarchical flow, if the block level design
# have SystemVerilog interfaces ports.  
# set_app_var link_portname_allow_period_to_match_underscore true

current_design ${DESIGN_NAME}

# Link the design
link

#################################################################################
# Reports pre-synthesis congestion analysis.
#################################################################################
# Check to make sure that all the correct designs were linked
# Pay special attention to the source location of your physical blocks
list_designs -show_file

# Report the block abstraction settings and usage
if { (${ICC_BLOCK_ABSTRACTION_DESIGNS} != "") || (${DC_BLOCK_ABSTRACTION_DESIGNS} != "") || (${DC_BLOCK_ABSTRACTION_DESIGNS_TIO} != "") } {
 report_top_implementation_options
 report_block_abstraction
}

# Don't optimize ${DDC_HIER_DESIGNS}
if { ${DDC_HIER_DESIGNS} != ""} {
  if {[shell_is_in_topographical_mode]} {
    # Hierarchical .ddc blocks must be marked as physical hierarchy
    # In case of multiply instantiated designs, only set_physical_hierarchy on ONE instance
    set_physical_hierarchy [sub_instances_of -hierarchy -master_instance -of_references ${DDC_HIER_DESIGNS} ${DESIGN_NAME}]
    get_physical_hierarchy
  } else {
    # Don't touch these blocks in DC-WLM
    set_dont_touch [get_designs ${DDC_HIER_DESIGNS}]
  }
}

# Prevent optimization of top-level logic based on physical block contents
# (required for hierarchical formal verification flow)
set_boundary_optimization ${HIERARCHICAL_DESIGNS} false
set_app_var compile_preserve_subdesign_interfaces true
set_app_var compile_enable_constant_propagation_with_no_boundary_opt false

###############################################################################
# Apply constraints
###############################################################################
# Our timing constraints are in a SDC file
read_sdc ${DCRM_SDC_INPUT_FILE}
source -echo -verbose ../scripts/dc/dc_routing.tcl
source -echo -verbose ../scripts/dc/${DESIGN_NAME}/dc_physical_constraints.tcl

# Verify that all the desired physical constraints have been applied
# Add the -pre_route option to include pre-routes in the report
report_physical_constraints > ${REPORTS_DIR}/${DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT}

#################################################################################
# Compile
#################################################################################
source -echo -verbose ../scripts/dc/dc_create_default_path_groups.tcl
source -echo -verbose ../scripts/dc/dc_pre_first_compile_hplp.tcl

compile_ultra

write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_COMPILE_ULTRA_DDC_OUTPUT_FILE}

###############################################################################
# Incremental compile
###############################################################################
source ../scripts/dc/dc_pre_incr_compile_hplp.tcl
# Creating path groups to reduce TNS
create_auto_path_groups -mode mapped

compile_ultra -incremental

# Remove auto generated path groups
remove_auto_path_groups
# Perform area recovery
optimize_netlist -area

###############################################################################
# Change nameing
###############################################################################
change_names -rules verilog -hierarchy

###############################################################################
# Write out extra design data and reports
###############################################################################
source ../scripts/dc/dc_write_extra_design_data.tcl
source ../scripts/dc/dc_generate_reports.tcl

#################################################################################
# Write out Top-Level Design Without Hierarchical Blocks
#################################################################################
# Note: The write command will automatically skip writing .ddc physical hierarchical
#       blocks in Design Compiler topographical mode and Design Compiler block 
#       abstractions blocks. DC WLM mode still need to be removed before writing out 
#       the top-level design. In the same way for the multivoltage flow, save_upf will 
#       skip hierarchical blocks when saving the power intent data.

# To remove the hierarchical blocks you can do
# if {![shell_is_in_topographical_mode]} {
#   if {[get_designs -quiet ${DDC_HIER_DESIGNS}] != "" } {
#     remove_design -hierarchy [get_designs -quiet ${DDC_HIER_DESIGNS}]
#   }
# }

# Writing out the updated Design Compiler blocks with transparent interface optimization
# foreach design "${DC_BLOCK_ABSTRACTION_DESIGNS_TIO}" {
#   write -format ddc -hierarchy -output ${RESULTS_DIR}/[dcrm_mapped_tio_filename $design] $design
# }

# Write out ddc mapped top-level design
write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}

# Write and close SVF file
set_svf -off
