complete -c plug -x -n __fish_use_subcommand -a "install uninstall list enable disable update"

complete -c plug -x -n "test (count (commandline -poc)) = 1" -s h -l help -d Help

complete -c plug -x -n "__fish_seen_subcommand_from uninstall rm update up" -a "(_plug_list)"

complete -c plug -x -n "__fish_seen_subcommand_from list" # Disable file completion
complete -c plug -x -n "__fish_seen_subcommand_from list" -s e -l enabled -d "List enabled plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list" -s d -l disabled -d "List disabled plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list" -s v -l verbose -d "Show plugin version and state"

complete -c plug -x -n "__fish_seen_subcommand_from enable" -a "(_plug_list --disabled)"

complete -c plug -x -n "__fish_seen_subcommand_from disable" -a "(_plug_list --enabled)"
