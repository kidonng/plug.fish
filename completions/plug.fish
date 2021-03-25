complete plug -x -n __fish_use_subcommand -a "install uninstall list enable disable update pin unpin"

complete plug -x -n __fish_is_first_arg -s h -l help -d Help

complete plug -x -n "__fish_seen_subcommand_from uninstall rm" -a "(_plug_list)"

complete plug -x -n "__fish_seen_subcommand_from list ls" # Disable file completion
complete plug -x -n "__fish_seen_subcommand_from list ls" -s e -l enabled -d "List enabled plugins"
complete plug -x -n "__fish_seen_subcommand_from list ls" -s d -l disabled -d "List disabled plugins"
complete plug -x -n "__fish_seen_subcommand_from list ls" -s p -l pinned -d "List pinned plugins"
complete plug -x -n "__fish_seen_subcommand_from list ls" -s u -l unpinned -d "List unpinned plugins"
complete plug -x -n "__fish_seen_subcommand_from list ls" -s s -l source -d "Show plugin source"
complete plug -x -n "__fish_seen_subcommand_from list ls" -s v -l verbose -d "Show plugin version and state"

complete plug -x -n "__fish_seen_subcommand_from enable" -a "(_plug_list --disabled)"

complete plug -x -n "__fish_seen_subcommand_from disable" -a "(_plug_list --enabled)"

complete plug -x -n "__fish_seen_subcommand_from update up pin" -a "(_plug_list --unpinned)"

complete plug -x -n "__fish_seen_subcommand_from unpin" -a "(_plug_list --pinned)"
