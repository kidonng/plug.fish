set commands "install uninstall list enable disable update"
complete -c plug -x -n __fish_use_subcommand -a $commands
complete -c plug -x -n "__fish_seen_subcommand_from $commands"

complete -c plug -x -s h -l help -d Help

complete -c plug -x -n "__fish_seen_subcommand_from uninstall rm update up" -a "(_plug_list)"

complete -c plug -x -n "__fish_seen_subcommand_from list" -s e -l enabled -d "Only list enabled plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list" -s d -l disabled -d "Only list disabled plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list" -s v -l verbose -d "Show plugin version and state"

complete -c plug -x -n "__fish_seen_subcommand_from enable" -a "(_plug_list --disabled)"

complete -c plug -x -n "__fish_seen_subcommand_from disable" -a "(_plug_list --enabled)"
