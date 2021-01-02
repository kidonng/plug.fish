source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/getopts.fish
set output (getopts --foo=bar --baz)
test "$output" = "foo bar baz true"
