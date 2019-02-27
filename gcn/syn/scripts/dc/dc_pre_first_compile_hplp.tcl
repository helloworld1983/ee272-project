###############################################################################
# Setup for first compile
###############################################################################
# Controls whether compile inserts extra logic into the design to ensure that
# there are no feedthroughs, or that there are no two output ports connected to
# the same net at any level of hierarchy. This prevents assignment statements
# in the Verilog netlist that can cause problems with other tools.
set_fix_multiple_port_nets -all -buffer_constants

# Enable support for via RC estimation to improve timing correlation with 
# IC Compiler
set_app_var spg_enable_via_resistance_support true

# The following variable, when set to true, runs additional optimizations to
# improve the timing of the design at the cost of additional run time.
# set_app_var compile_timing_high_effort true

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
