function plug -a cmd
    test -z "$XDG_DATA_HOME" && set XDG_DATA_HOME ~/.local/share
    test -z "$plug_path" && set -U plug_path $XDG_DATA_HOME/fish/plug
    test -e $plug_path || command mkdir -p $plug_path

    set dirs conf.d functions completions

    switch "$cmd"
        case install add
            set plugins $argv[2..]
            set installed (plug list)

            for plugin in $plugins
                if builtin contains $plugin $installed
                    echo $plugin is already installed
                    continue
                end

                echo Cloning $plugin
                echo $plugin | read -d / owner repo
                command git clone https://github.com/$plugin $plug_path/$owner/$repo

                plug enable $plugin
            end
        case uninstall rm
            set plugins $argv[2..]
            set installed (plug list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                plug disable $plugin

                echo Removing $plugin
                echo $plugin | read -d / owner repo
                command rm -rf $plug_path/$owner/$repo
            end
        case list ls
            set plugins (command find $plug_path -type d -mindepth 2 -maxdepth 2)

            for plugin in $plugins
                string join / (string split / $plugin)[-2..]
            end
        case enable
            set plugins $argv[2..]
            set installed (plug list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                echo Linking $plugin
                set plugin_path $plug_path/$plugin
                for dir in $dirs
                    command ln -s $plugin_path/$dir/* $__fish_config_dir/$dir/
                end

                echo Setting $plugin

                for func in $plugin_path/functions/*
                    builtin source $func
                end

                set conf_path $plugin_path/conf.d
                for conf in $conf_path/*
                    builtin source $conf
                    builtin emit (string replace $conf_path/ '' $conf | string replace .fish _install)
                end
            end
        case disable
            set plugins $argv[2..]
            set installed (plug list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                echo Unlinking $plugin
                set plugin_path $plug_path/$plugin
                for dir in $dirs
                    command rm (string replace $plugin_path $__fish_config_dir $plugin_path/$dir/*)
                end

                echo Unsetting $plugin

                set conf_path $plugin_path/conf.d
                for conf in $conf_path/*
                    builtin emit (string replace $conf_path/ '' $conf | string replace .fish _uninstall)
                end

                set func_path $plugin_path/functions
                for func in $func_path/*
                    builtin functions -e (string replace $func_path/ '' $func | string replace .fish '')
                end
            end
        case update up
            set plugins $argv[2..]
            set installed (plug list)
            test -z "$plugins" && set plugins $installed

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                echo Updating $plugin
                set plugin_path $plug_path/$plugin
                command git -C $plugin_path fetch

                set local (command git -C $plugin_path rev-parse HEAD)
                set origin (command git -C $plugin_path rev-parse FETCH_HEAD)

                if test $local != $origin
                    plug disable $plugin
                    command git -C $plugin_path pull --rebase
                    plug enable $plugin
                end
            end
    end
end
