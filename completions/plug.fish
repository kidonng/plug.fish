complete -c plug -x -n __fish_use_subcommand -a "install uninstall list enable disable update pin unpin"

complete -c plug -x -n __fish_is_first_arg -s h -l help -d Help

complete -c plug -x -n "__fish_seen_subcommand_from uninstall rm" -a "(_plug_list)"

complete -c plug -x -n "__fish_seen_subcommand_from list ls" # Disable file completion
complete -c plug -x -n "__fish_seen_subcommand_from list ls" -s e -l enabled -d "List enabled plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list ls" -s d -l disabled -d "List disabled plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list ls" -s p -l pinned -d "List pinned plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list ls" -s u -l unpinned -d "List unpinned plugins"
complete -c plug -x -n "__fish_seen_subcommand_from list ls" -s s -l source -d "Show plugin source"
complete -c plug -x -n "__fish_seen_subcommand_from list ls" -s v -l verbose -d "Show plugin version and state"

complete -c plug -x -n "__fish_seen_subcommand_from enable" -a "(_plug_list --disabled)"

complete -c plug -x -n "__fish_seen_subcommand_from disable" -a "(_plug_list --enabled)"

complete -c plug -x -n "__fish_seen_subcommand_from update up pin" -a "(_plug_list --unpinned)"
complete -c plug -x -n "__fish_seen_subcommand_from update up" -s f -l force -d "Force update pinned plugins"

complete -c plug -x -n "__fish_seen_subcommand_from unpin" -a "(_plug_list --pinned)"
