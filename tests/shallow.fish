source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/getopts.fish
test (git -C $plug_path/jorgebucaran/getopts.fish rev-parse --is-shallow-repository) = true
