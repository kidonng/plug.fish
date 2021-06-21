complete plug -x -n __fish_use_subcommand -a "install uninstall list init enable disable update pin unpin"

complete plug -x -n __fish_is_first_arg -s h -l help -d "Show usage information"

complete plug -x -n "__fish_seen_subcommand_from uninstall rm" -a "(plug list)"

complete plug -x -n "__fish_seen_subcommand_from list ls" -a "(plug list)"
complete plug -n "__fish_seen_subcommand_from list ls" -s e -l enabled -d "List enabled plugins"
complete plug -n "__fish_seen_subcommand_from list ls" -s d -l disabled -d "List disabled plugins"
complete plug -n "__fish_seen_subcommand_from list ls" -s p -l pinned -d "List pinned plugins"
complete plug -n "__fish_seen_subcommand_from list ls" -s u -l unpinned -d "List unpinned plugins"

complete plug -x -n "__fish_seen_subcommand_from enable" -a "(plug list -d)"

complete plug -x -n "__fish_seen_subcommand_from disable" -a "(plug list -e)"

complete plug -x -n "__fish_seen_subcommand_from update up pin" -a "(plug list -u)"

complete plug -x -n "__fish_seen_subcommand_from unpin" -a "(plug list -p)"
