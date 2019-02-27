###############################################################################
# Setup for incremental compile
###############################################################################
# Enable congestion-driven  placement  in incremental compile to improve congestion
set_app_var spg_congestion_placement_in_incremental_compile true

# If we have an incremental don't use list, source it here
if {[file exists [which ${LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST}]]} {
  puts "Info: Sourcing script file [which ${LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST}]\n"
  source -echo -verbose $LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST
}
