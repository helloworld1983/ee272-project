#!/bin/bash

export TERM="xterm+256color"
export SAED32_EDK_PATH="/cad/synopsys_EDK3/SAED32_EDK"

if  [ -z $SYNOPSYSICC ]; then
  echo "Module icc must be loaded before running icc2"
  exit 1
fi
export ICC_BIN_PATH="$SYNOPSYSICC/bin/icc_shell"

# Note that the icc2 module must be loaded before icc2 can run
# Uncomment the following lines if it's not done already
# export MODULESHOME=/cad/modules/tcl
# source $MODULESHOME/init/bash.in
# module load base lc syn icc icc2
cd work && icc2_shell -x "set_app_options -name lib.configuration.icc_shell_exec -value $ICC_BIN_PATH" "$@"
