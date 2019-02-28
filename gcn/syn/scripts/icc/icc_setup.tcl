puts "Info: Running script [info script]"

# TODO: fixme
set DESIGN_NAME "mac4x4"

source ../scripts/common/common_setup.tcl

#################################################################################
# Setup Variables
#################################################################################
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
set mw_design_library    ${DESIGN_NAME}_LIB

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
