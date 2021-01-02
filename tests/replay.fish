source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/replay.fish
replay 'die() { return 123; }; die'
test $status = 123
