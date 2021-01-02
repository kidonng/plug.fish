source $GITHUB_WORKSPACE/functions/plug.fish

plug install $GITHUB_WORKSPACE
test (plug list) = local/fish-plug
