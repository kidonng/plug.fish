complete -c plug -x -n __fish_use_subcommand -a install
complete -c plug -x -n __fish_use_subcommand -a uninstall
complete -c plug -x -n __fish_use_subcommand -a list
complete -c plug -x -n __fish_use_subcommand -a enable
complete -c plug -x -n __fish_use_subcommand -a disable
complete -c plug -x -n __fish_use_subcommand -a update
complete -c plug -x -n "__fish_seen_subcommand_from uninstall rm enable disable update up" -a "(plug list)"
