function plug -a cmd
    test -z "$XDG_DATA_HOME" && set XDG_DATA_HOME ~/.local/share
    test -z "$plug_path" && set -U plug_path $XDG_DATA_HOME/fish/plug
    test -e $plug_path || command mkdir -p $plug_path

    switch "$cmd"
        case install add
            set plugins $argv[2..-1]
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
            set plugins $argv[2..-1]
            set installed (plug list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                plug disable $plugin

                echo Removing $plugin
                echo $plugin | read -d / owner repo
                set owner_path $plug_path/$owner
                command rm -rf $owner_path/$repo

                set owner_plugins $owner_path/*
                if test -z "$owner_plugins"
                    command rm -r $owner_path
                end
            end
        case list ls
            set plugins (command find $plug_path -type d -mindepth 2 -maxdepth 2)

            for plugin in $plugins
                string join / (string split / $plugin)[-2..-1]
            end
        case enable
            set plugins $argv[2..-1]
            set installed (plug list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                echo Enabling $plugin
                set plugin_path $plug_path/$plugin
                set link_files

                for file in $plugin_path/functions/*
                    set -a link_files $file
                    builtin source $file
                end

                set conf_path $plugin_path/conf.d
                for file in $conf_path/*
                    set -a link_files $file
                    builtin source $file
                    builtin emit (string replace $conf_path/ '' $file | string replace .fish _install)
                end

                for file in $plugin_path/completions/*
                    set -a link_files $file
                    builtin source $file
                end

                for file in $link_files
                    command ln -s $file (string replace $plugin_path $__fish_config_dir $file)
                end
            end
        case disable
            set plugins $argv[2..-1]
            set installed (plug list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                echo Disabling $plugin
                set plugin_path $plug_path/$plugin
                set unlink_files

                set conf_path $plugin_path/conf.d
                for file in $conf_path/*
                    set -a unlink_files $file
                    builtin emit (string replace $conf_path/ '' $file | string replace .fish _uninstall)
                end

                set func_path $plugin_path/functions
                for file in $func_path/*
                    set -a unlink_files $file
                    builtin functions -e (string replace $func_path/ '' $file | string replace .fish '')
                end

                for file in $plugin_path/completions/*
                    set -a unlink_files $file
                end

                for file in $unlink_files
                    command rm (string replace $plugin_path $__fish_config_dir $file)
                end
            end
        case update up
            set plugins $argv[2..-1]
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
