source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/humantime.fish
test (humantime 11655400) = "3h 14m 15s"
