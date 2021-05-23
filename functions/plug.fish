test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug
set _plug_regex '([^/]+)\.fish$'

function plug -a cmd -d "Manage Fish plugins"
    set plugins (string match -v -- "-*" $argv[2..])

    switch $cmd
        case "" -h --help
            printf "%s\n" \
                "Usage: plug "(set_color -o)"install"(set_color normal)"    <plugins>" \
                "       plug "(set_color -o)"uninstall"(set_color normal)"  <plugins>" \
                "       plug "(set_color -o)"list"(set_color normal)"       [options]" \
                "       plug "(set_color -o)"init"(set_color normal) \
                "       plug "(set_color -o)"enable"(set_color normal)"     <plugins>" \
                "       plug "(set_color -o)"disable"(set_color normal)"    <plugins>" \
                "       plug "(set_color -o)"update"(set_color normal)"     [plugins]" \
                "       plug "(set_color -o)"pin"(set_color normal)"        <plugins>" \
                "       plug "(set_color -o)"unpin"(set_color normal)"      <plugins>"
        case install add
        case uninstall rm
        case list ls
            argparse e/enabled d/disabled p/pinned u/unpinned -- $argv || return
            set -q argv[2] && set filter $argv[2]

            for author_path in $plug_path/*
                set author (string replace $plug_path/ "" $author_path)

                for plugin_path in $author_path/*
                    set plugin (string replace $author_path/ "" $plugin_path)
                    set plugin_full $author/$plugin

                    if set -q _flag_enabled && ! contains $plugin_full $_plug_enabled
                        or set -q _flag_disabled && contains $plugin_full $_plug_enabled
                        or set -q _flag_pinned && contains $plugin_full $_plug_unpinned
                        or set -q _flag_unpinned && ! contains $plugin_full $_plug_unpinned
                        or set -q filter && ! string match -rq $filter $plugin_full
                        continue
                    end

                    if isatty stdout
                        set plugin_styled $author/(set_color -o)$plugin(set_color normal)

                        if ! contains $plugin_full $_plug_enabled
                            set plugin_styled (set_color -d)$plugin_styled
                        end

                        if ! contains $plugin_full $_plug_unpinned
                            set plugin_styled (set_color -u)$plugin_styled
                        end

                        echo $plugin_styled
                    else
                        echo $author/$plugin
                    end
                end
            end
        case init
            argparse s/script -- $argv || return

            if set -q _flag_script
                printf "%s\n" \
                    "set -l plug "(string replace $plug_path '$plug_path' (status -f) | string replace ~ "~") \
                    'test -f $plug && source $plug && plug init'
                return 0
            end

            if set -q _plug_initialized
                echo plug: already initialized >&2
                return 1
            end

            set -g _plug_initialized

            for plugin_path in $plug_path/$_plug_enabled
                test -d $plugin_path/completions && set -a complete_path $plugin_path/completions
                test -d $plugin_path/functions && set -a function_path $plugin_path/functions
            end

            set fish_complete_path $fish_complete_path[1] $complete_path $fish_complete_path[2..]
            set fish_function_path $fish_function_path[1] $function_path $fish_function_path[2..]

            status -i || return 0

            for file in $plug_path/$_plug_enabled/conf.d/*.fish
                source $file
            end
        case enable
            for plugin in $plugins
                set plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _plug_error && continue
                end

                if contains $plugin $_plug_enabled
                    echo plug: (set_color -o)$plugin(set_color normal) is already enabled >&2
                    set _plug_error && continue
                end

                for file in $plugin_path/{completions,functions}/*.fish
                    source $file
                end

                for file in $plugin_path/conf.d/*.fish
                    source $file
                    emit (string match -r $_plug_regex $file)[2]_install
                end

                set -Ua _plug_enabled $plugin
                echo plug: (set_color -o)$plugin(set_color normal) enabled
            end
        case disable
            for plugin in $plugins
                set plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _plug_error && continue
                end

                if ! set index (contains -i $plugin $_plug_enabled)
                    echo plug: (set_color -o)$plugin(set_color normal) is already disabled >&2
                    set _plug_error && continue
                end

                for file in $plugin_path/conf.d/*.fish
                    emit (string match -r $_plug_regex $file)[2]_uninstall
                end

                for file in $plugin_path/functions/*.fish
                    functions -e (string match -r $_plug_regex $file)[2]
                end

                for file in $plugin_path/completions/*.fish
                    complete -e (string match -r $_plug_regex $file)[2]
                end

                set -e _plug_enabled[$index]
                echo plug: (set_color -o)$plugin(set_color normal) disabled
            end
        case update up
        case pin
            for plugin in $plugins
                set plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _plug_error && continue
                end

                if ! set index (contains -i $plugin $_plug_unpinned)
                    echo plug: (set_color -o)$plugin(set_color normal) is already pinned >&2
                    set _plug_error && continue
                end

                set -e _plug_unpinned[$index]
                echo plug: (set_color -o)$plugin(set_color normal) pinned
            end
        case unpin
            for plugin in $plugins
                set plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _plug_error && continue
                end

                if contains $plugin $_plug_unpinned
                    echo plug: (set_color -o)$plugin(set_color normal) is already unpinned >&2
                    set _plug_error && continue
                end

                set -Ua _plug_unpinned $plugin
                echo plug: (set_color -o)$plugin(set_color normal) unpinned
            end
        case "*"
            echo plug: Unknown command (set_color -o)$cmd(set_color normal) >&2
            return 1
    end

    if set -q _plug_error
        return 1
    end
end
