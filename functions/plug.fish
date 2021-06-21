test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug

function plug -a cmd -d "Manage Fish plugins"
    set -l plugins (string match -v -- "-*" $argv[2..])
    set -l regex '([^/]+)\.fish$'
    set -l _status 0

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

            for author_path in $plug_path/*
                set -l author (string replace $plug_path/ "" $author_path)

                for plugin_path in $author_path/*
                    set -l plugin (string replace $author_path/ "" $plugin_path)
                    set -l plugin_full $author/$plugin

                    if set -q _flag_enabled && ! contains $plugin_full $plug_enabled
                        or set -q _flag_disabled && contains $plugin_full $plug_enabled
                        or set -q _flag_pinned && contains $plugin_full $plug_unpinned
                        or set -q _flag_unpinned && ! contains $plugin_full $plug_unpinned
                        or set -q plugins[1] && ! contains $plugin_full $plugins
                        continue
                    end

                    if isatty stdout
                        set -l plugin_styled $author/(set_color -o)$plugin(set_color normal)

                        if ! contains $plugin_full $plug_enabled
                            set plugin_styled (set_color -d)$plugin_styled
                        end

                        if ! contains $plugin_full $plug_unpinned
                            set plugin_styled (set_color -u)$plugin_styled
                        end

                        echo $plugin_styled
                    else
                        echo $author/$plugin
                    end

                    if set -q plugins[1]
                        for dir in completions conf.d functions
                            set -l dir_path $plugin_path/$dir
                            set -l files $dir_path/*.fish

                            if test (count $files) -gt 0
                                string replace -- $dir_path (set_color -o)$dir(set_color normal) \t$files
                            end
                        end
                    end
                end
            end
        case init
            if set -q _plug_initialized
                echo plug: already initialized >&2
                return 1
            end

            set -g _plug_initialized

            set fish_complete_path $fish_complete_path[1] $plug_path/$plug_enabled/completions $fish_complete_path[2..]
            set fish_function_path $fish_function_path[1] $plug_path/$plug_enabled/functions $fish_function_path[2..]

            set -q _PLUG_CONF_PATH || set -gx _PLUG_CONF_PATH $plug_path/$plug_enabled/conf.d/*.fish
            _plug_source $_PLUG_CONF_PATH
        case enable
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _status 1 && continue
                end

                if contains $plugin $plug_enabled
                    echo plug: (set_color -o)$plugin(set_color normal) is already enabled >&2
                    set _status 1 && continue
                end

                for file in $plugin_path/{completions,functions}/*.fish
                    source $file
                end

                for file in $plugin_path/conf.d/*.fish
                    source $file
                    emit (string match -r $regex $file)[2]_install
                end

                set -Ua plug_enabled $plugin
                echo plug: (set_color -o)$plugin(set_color normal) enabled
            end
        case disable
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _status 1 && continue
                end

                if ! set -l index (contains -i $plugin $plug_enabled)
                    echo plug: (set_color -o)$plugin(set_color normal) is already disabled >&2
                    set _status 1 && continue
                end

                for file in $plugin_path/conf.d/*.fish
                    emit (string match -r $regex $file)[2]_uninstall
                end

                for file in $plugin_path/functions/*.fish
                    functions -e (string match -r $regex $file)[2]
                end

                for file in $plugin_path/completions/*.fish
                    complete -e (string match -r $regex $file)[2]
                end

                set -e plug_enabled[$index]
                echo plug: (set_color -o)$plugin(set_color normal) disabled
            end
        case update up
        case pin
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _status 1 && continue
                end

                if ! set -l index (contains -i $plugin $plug_unpinned)
                    echo plug: (set_color -o)$plugin(set_color normal) is already pinned >&2
                    set _status 1 && continue
                end

                set -e plug_unpinned[$index]
                echo plug: (set_color -o)$plugin(set_color normal) pinned
            end
        case unpin
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) does not exist >&2
                    set _status 1 && continue
                end

                if contains $plugin $plug_unpinned
                    echo plug: (set_color -o)$plugin(set_color normal) is already unpinned >&2
                    set _status 1 && continue
                end

                set -Ua plug_unpinned $plugin
                echo plug: (set_color -o)$plugin(set_color normal) unpinned
            end
        case "*"
            echo plug: Unknown command (set_color -o)$cmd(set_color normal) >&2
            return 1
    end

    return $_status
end

function _plug_source
    for file in $argv
        if ! test -f (string replace -r "^.*/" $__fish_config_dir/conf.d/ -- $file)
            source $file
        end
    end
end
