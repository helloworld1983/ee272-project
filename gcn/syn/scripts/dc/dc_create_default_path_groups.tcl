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
