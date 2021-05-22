test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug

function plug -a cmd -d "Manage Fish plugins"
    set plugins (string match -v -- "-*" $argv[2..])

    switch $cmd
        case "" -h --help
            printf "%s\n" \
                "Usage: plug "(set_color -o)"install"(set_color normal)"    <plugins>" \
                "       plug "(set_color -o)"uninstall"(set_color normal)"  <plugins>" \
                "       plug "(set_color -o)"list"(set_color normal)"       [options]" \
                "       plug "(set_color -o)"enable"(set_color normal)"     <plugins>" \
                "       plug "(set_color -o)"disable"(set_color normal)"    <plugins>" \
                "       plug "(set_color -o)"update"(set_color normal)"     [plugins]" \
                "       plug "(set_color -o)"pin"(set_color normal)"        <plugins>" \
                "       plug "(set_color -o)"unpin"(set_color normal)"      <plugins>"
        case install add
        case uninstall rm
        case list ls
        case enable
        case disable
        case update up
        case pin
        case unpin
        case "*"
            echo plug: Unknown command (set_color -o)$cmd(set_color normal) >&2
            return 1
    end
end
