source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/nvm.fish
nvm install 6
test (nvm current) = v6.17.1
