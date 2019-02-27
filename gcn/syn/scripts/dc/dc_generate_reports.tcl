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
