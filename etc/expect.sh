#!/bin/sh

# ensure no readline config breaks things
export INPUTRC=/tmp/inputrc

# disable GAP banner
export GAP_PRINT_BANNER=false

expect -c "spawn julia --startup-file=no --color=no --history-file=no --banner=no $*" etc/julia.expect
