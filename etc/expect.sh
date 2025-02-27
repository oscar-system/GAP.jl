#!/bin/sh

# ensure no readline config breaks things
export INPUTRC=/tmp/inputrc

# disable GAP banner
export GAP_PRINT_BANNER=false

# force Julia to use full REPL
export TERM=xterm

expect -c "spawn julia --startup-file=no --history-file=no --banner=no $* -e \"atreplinit() do repl; if VERSION >= v\\\"1.11.0-0\\\"; repl.options.hint_tab_completes = false; end; end;\" -i" etc/julia.expect
