###############################################################################
# Write out extra design data
###############################################################################
# Write out ICC2 files
write_icc2_files -force -output ${RESULTS_DIR}/${DCRM_FINAL_DESIGN_ICC2}

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
