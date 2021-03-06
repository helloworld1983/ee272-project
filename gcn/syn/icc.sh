#!/bin/bash

export TERM="xterm+256color"
export SAED32_EDK_PATH="/cad/synopsys_EDK3/SAED32_EDK"

# Note that the icc module must be loaded before icc can run
# Uncomment the following lines if it's not done already
# export MODULESHOME=/cad/modules/tcl
# source $MODULESHOME/init/bash.in
# module load base lc syn icc
cd work && icc_shell "$@"
