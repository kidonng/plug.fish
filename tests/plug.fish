source $GITHUB_WORKSPACE/functions/plug.fish

plug install $GITHUB_WORKSPACE
string match -q local/plug.fish (plug list)
