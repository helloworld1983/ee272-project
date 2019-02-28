# Specify ignored layers for routing to improve correlation
# Use the same ignored layers that will be used during place and route
if { ${MIN_ROUTING_LAYER} != ""} {
  set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
}
if { ${MAX_ROUTING_LAYER} != ""} {
  set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
}

# Set the preferred routing directions if not already specified
if {$ROUTING_LAYER_DIRECTION_OFFSET_LIST != ""} {
  foreach direction_offset_pair $ROUTING_LAYER_DIRECTION_OFFSET_LIST {
    set layer [lindex $direction_offset_pair 0]
    set direction [lindex $direction_offset_pair 1]
    set offset [lindex $direction_offset_pair 2] 
    set_attribute [get_layers $layer] routing_direction $direction
    if {$offset != ""} {
      set_attribute [get_layers $layer] track_offset $offset
    }
  }
} else {
  puts "Error: ROUTING_LAYER_DIRECTION_OFFSET_LIST is not specified."
  puts "       You must manually set routing layer directions and offsets!"
}
