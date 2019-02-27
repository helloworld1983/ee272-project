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
# Autoread settings
###############################################################################
# Set the filenames we recognize for each RTL type
# Only needed for the "-autoread" option of analyze
set_app_var hdlin_autoread_verilog_extensions    ".v"
set_app_var hdlin_autoread_sverilog_extensions   ".sv .sverilog"
set_app_var hdlin_autoread_vhdl_extensions       ".vhd .vhdl"

# Define the folder to use for temporary files
define_design_lib WORK -path ./WORK

# Helps verification resolve differences between DC and FM
set_app_var hdlin_enable_hier_map true

