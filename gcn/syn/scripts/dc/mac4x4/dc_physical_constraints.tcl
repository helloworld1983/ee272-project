###############################################################################
# Apply Physical Design Constraints
###############################################################################
# Specify ignored layers for routing to improve correlation
# Use the same ignored layers that will be used during place and route
if { ${MIN_ROUTING_LAYER} != ""} {
  set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
}
if { ${MAX_ROUTING_LAYER} != ""} {
  set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
}

# report_ignored_layers

# Optional: Floorplan information can be read in here if available.
# read_floorplan ${DCRM_DCT_FLOORPLAN_INPUT_FILE}.objects
# read_floorplan ${DCRM_DCT_FLOORPLAN_INPUT_FILE}

#################################################################################
# Apply Additional Optimization Constraints
#################################################################################
# None
