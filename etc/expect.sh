#!/bin/sh

# ensure no readline config breaks things
export INPUTRC=/tmp/inputrc

# disable GAP banner
export GAP_PRINT_BANNER=false

# force Julia to use full REPL
export TERM=xterm

julia_args="$* --startup-file=no --history-file=no --banner=no --color=no"
# start julia with GAP once with the exact same flags to ensure precompilation
# happens outside of expect, since its output messes up the expect script
julia ${julia_args} -e "using GAP"

expect -c "spawn julia ${julia_args} -e \"
atreplinit() do repl
  if VERSION >= v\\\"1.11.0-DEV.456\\\" # JuliaLang/julia#51229
    repl.options.hint_tab_completes = false
  end
end\" -i" etc/julia.expect
