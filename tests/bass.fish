fish -c "
  source $GITHUB_WORKSPACE/functions/plug.fish
  plug install edc/bass
"
bass 'die() { return 123; }; die'
test $status = 123
