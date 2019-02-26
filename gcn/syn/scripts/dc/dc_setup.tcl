puts "Info: Running script [info script]"
source ../scripts/common/common_setup.tcl
source ../scripts/dc/dc_setup_filenames.tcl

if {![shell_is_in_topographical_mode]} {
  puts "Error: dc_shell must be run in topographical mode."
  exit 1
}

#################################################################################
# Setup Variables
#################################################################################
# The following setting removes new variable info messages from the end of the log file
set_app_var sh_new_variable_message false

if {$synopsys_program_name == "dc_shell"}  {
  #################################################################################
  # Design Compiler Setup Variables
  #################################################################################
  set_host_options -max_cores 8

  # Change alib_library_analysis_path to point to a central cache of analyzed libraries
  # to save runtime and disk space.  The following setting only reflects the
  # default value and should be changed to a central location for best results.
  set_app_var alib_library_analysis_path .

  # Add any additional Design Compiler variables needed here
}

set REPORTS_DIR "../reports"
set RESULTS_DIR "../results"

file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}

#################################################################################
# Search Path Setup
#################################################################################
set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"

###############################################################################
# Milkyway library setup
###############################################################################
# Milkyway variable settings
# Make sure to define the Milkyway library variable
# mw_design_library, it is needed by write_milkyway command
set mw_reference_library ${MW_REFERENCE_LIB_DIRS}
set mw_design_library    ${DCRM_MW_LIBRARY_NAME}

set mw_site_name_mapping { {CORE unit} {Core unit} {core unit} }

###############################################################################
# Library setup
###############################################################################
set_app_var target_library ${TARGET_LIBRARY_FILES}
set_app_var synthetic_library dw_foundation.sldb

# Enabling the usage of DesignWare minPower Components requires additional DesignWare-LP license
set_app_var synthetic_library "dw_minpower.sldb  dw_foundation.sldb"

set_app_var link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"

# Set min libraries if they exist
foreach {max_library min_library} $MIN_LIBRARY_FILES {
  echo "set_min_library $max_library -min_version $min_library"
  set_min_library $max_library -min_version $min_library
}

# Only create new Milkyway design library if it doesn't already exist
if {![file isdirectory $mw_design_library ]} {
  create_mw_lib \
    -technology $TECH_FILE \
    -mw_reference_library $mw_reference_library \
    $mw_design_library
} else {
  # If Milkyway design library already exists, ensure that it is consistent
  # with specified Milkyway reference libraries
  set_mw_lib_reference $mw_design_library -mw_reference_library $mw_reference_library
}

open_mw_lib $mw_design_library

check_library > ${REPORTS_DIR}/${DCRM_CHECK_LIBRARY_REPORT}

set_tlu_plus_files \
  -max_tluplus $TLUPLUS_MAX_FILE \
  -min_tluplus $TLUPLUS_MIN_FILE \
  -tech2itf_map $MAP_FILE

check_tlu_plus_files

#################################################################################
# Library Modifications
#
# Apply library modifications after the libraries are loaded.
#################################################################################

if {[file exists [which ${LIBRARY_DONT_USE_FILE}]]} {
  puts "Info: Sourcing script file [which ${LIBRARY_DONT_USE_FILE}]\n"
  source -echo -verbose ${LIBRARY_DONT_USE_FILE}
}

puts "Info: Completed script [info script]"
