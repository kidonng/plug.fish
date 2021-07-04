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
            test -z "$PLUG_GIT" && set -l PLUG_GIT --depth 1 -q
            test -z "$PLUG_REMOTE" && set -l PLUG_REMOTE https://github.com/
            set -l tmp (mktemp)
            set -l pid

            for plugin in $plugins
                if test -d $plug_path/$plugin
                    echo plug: (set_color -o)$plugin(set_color normal) is already installed >&2
                    set _status 1 && continue
                end

                fish -c "
                    echo plug: cloning $PLUG_REMOTE(set_color -o)$plugin(set_color normal)

                    if git clone $PLUG_GIT $PLUG_REMOTE$plugin $plug_path/$plugin
                        echo plug enable $plugin >> $tmp
                    else
                        echo plug: failed to install (set_color -o)$plugin(set_color normal) >&2
                        echo set _status 1 >> $tmp
                    end
                " &

                set -a pid (jobs -lp)
            end

            wait $pid
            source $tmp
            rm $tmp
        case uninstall rm
            for plugin in $plugins
                if ! test -d $plug_path/$plugin
                    echo plug: (set_color -o)$plugin(set_color normal) is not installed >&2
                    set _status 1 && continue
                end

                if contains $plugin $plug_enabled && ! plug disable $plugin
                    echo plug: failed to disable (set_color -o)$plugin(set_color normal), skipping uninstall >&2
                    set _status 1 && continue
                end

                rm -rf $plug_path/$plugin
                echo plug: uninstalled (set_color -o)$plugin(set_color normal)
            end

            if ! functions -q plug && test (count $plug_path/*) = 0
                rm -d $plug_path
                set -e plug_path
                functions -e plug
                echo (set_color -o)plug.fish(set_color normal) is fully uninstalled
            end
        case list ls
            argparse e/enabled d/disabled p/pinned u/unpinned -- $argv || return

            for author_path in $plug_path/*
                set -l author (string replace $plug_path/ "" $author_path)

                for plugin_path in $author_path/*
                    set -l plugin (string replace $author_path/ "" $plugin_path)
                    set -l plugin_full $author/$plugin

                    if set -q _flag_enabled && ! contains $plugin_full $plug_enabled
                        or set -q _flag_disabled && contains $plugin_full $plug_enabled
                        or set -q _flag_pinned && ! contains $plugin_full $plug_pinned
                        or set -q _flag_unpinned && contains $plugin_full $plug_pinned
                        or set -q plugins[1] && ! contains $plugin_full $plugins
                        continue
                    end

                    if isatty stdout
                        set -l plugin_styled $author/(set_color -o)$plugin(set_color normal)

                        if ! contains $plugin_full $plug_enabled
                            set plugin_styled (set_color -d)$plugin_styled
                        end

                        if contains $plugin_full $plug_pinned
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
            test -z "$plug_enabled" && return

            set -gq plug_enabled && set -g --path plug_enabled $plug_enabled

            set fish_complete_path $fish_complete_path[1] \
                $plug_path/$plug_enabled/completions \
                $fish_complete_path[2..]
            set fish_function_path $fish_function_path[1] \
                $plug_path/$plug_enabled/functions \
                $fish_function_path[2..]

            for file in $plug_path/$plug_enabled/conf.d/*.fish
                if ! test -f (string replace -r "^.*/" $__fish_config_dir/conf.d/ -- $file)
                    source $file
                end
            end
        case enable
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) is not installed >&2
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

                set -Ua --path plug_enabled $plugin
                echo plug: enabled (set_color -o)$plugin(set_color normal)
            end
        case disable
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) is not installed >&2
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
                echo plug: disabled (set_color -o)$plugin(set_color normal)
            end
        case update up
            test (count $plugins) = 0 && set plugins (plug list -e)

            for plugin in $plugins
                if ! test -d $plug_path/$plugin
                    echo plug: (set_color -o)$plugin(set_color normal) is not installed >&2
                    set _status 1 && continue
                end

                echo plug: updating (set_color -o)$plugin(set_color normal)
                git -C $plug_path/$plugin pull
            end
        case pin
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) is not installed >&2
                    set _status 1 && continue
                end

                if contains $plugin $plug_pinned
                    echo plug: (set_color -o)$plugin(set_color normal) is already pinned >&2
                    set _status 1 && continue
                end

                set -Ua plug_pinned $plugin
                echo plug: pinned (set_color -o)$plugin(set_color normal)
            end
        case unpin
            for plugin in $plugins
                set -l plugin_path $plug_path/$plugin

                if ! test -d $plugin_path
                    echo plug: (set_color -o)$plugin(set_color normal) is not installed >&2
                    set _status 1 && continue
                end

                if ! set -l index (contains -i $plugin $plug_pinned)
                    echo plug: (set_color -o)$plugin(set_color normal) is already unpinned >&2
                    set _status 1 && continue
                end

                set -e plug_pinned[$index]
                echo plug: unpinned (set_color -o)$plugin(set_color normal)
            end
        case "*"
            echo plug: Unknown command (set_color -o)$cmd(set_color normal) >&2
            return 1
    end

    return $_status
end
