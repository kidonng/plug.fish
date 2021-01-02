source $GITHUB_WORKSPACE/functions/plug.fish

plug install jorgebucaran/spark.fish
test (seq 8 | spark) = ▁▂▃▄▅▆▇█
