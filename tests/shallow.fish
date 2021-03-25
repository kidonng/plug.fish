source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/getopts.fish

if test (git -C $plug_path/jorgebucaran/getopts.fish rev-parse --is-shallow-repository) = true
    echo "Shallow git clone"
else
    echo "Full git clone"
    exit 1
end
