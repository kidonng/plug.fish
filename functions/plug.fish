function plug -a cmd
    test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug
    test -e $plug_path || command mkdir -p $plug_path
    set plug kidonng/fish-plug
    set plugins $argv[2..-1]
    set installed (_plug_list)

    switch "$cmd"
        case install add
            for plugin in $plugins
                if builtin contains $plugin $installed
                    echo $plugin is already installed
                    continue
                end

                _plug_install $plugin
            end
        case uninstall rm
            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                _plug_uninstall $plugin
            end

            if builtin contains $plug $plugins
                command rm -r $plug_path
                set -e plug_path

                for func in install uninstall list enable disable update
                    builtin functions -e _plug_$func
                end
            end
        case list ls
            _plug_list
        case enable
            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                _plug_enable $plugin install
            end
        case disable
            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                _plug_disable $plugin uninstall
            end
        case update up
            test -z "$plugins" && set plugins $installed

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                _plug_update $plugin
            end
    end
end

function _plug_install -a plugin
    echo Cloning $plugin
    echo $plugin | read -d / owner repo
    command git clone https://github.com/$plugin $plug_path/$owner/$repo

    _plug_enable $plugin install
end

function _plug_uninstall -a plugin
    _plug_disable $plugin uninstall

    echo Removing $plugin
    echo $plugin | read -d / owner repo
    set owner_path $plug_path/$owner
    command rm -rf $owner_path/$repo

    set owner_plugins $owner_path/*.fish
    if test -z "$owner_plugins"
        command rm -r $owner_path
    end
end

function _plug_list
    for plugin in $plug_path/*/*
        string join / (string split / $plugin)[-2..-1]
    end
end

function _plug_enable -a plugin event
    echo Enabling $plugin
    set plugin_path $plug_path/$plugin
    set link_files

    for file in $plugin_path/functions/*.fish
        set -a link_files $file
        builtin source $file
    end

    set conf_path $plugin_path/conf.d
    for file in $conf_path/*.fish
        set -a link_files $file
        builtin source $file
        builtin emit (string replace $conf_path/ '' $file | string replace .fish _$event)
    end

    for file in $plugin_path/completions/*.fish
        set -a link_files $file
    end

    for file in $link_files
        command ln -s $file (string replace $plugin_path $__fish_config_dir $file)
    end
end

function _plug_disable -a plugin event
    echo Disabling $plugin
    set plugin_path $plug_path/$plugin
    set unlink_files

    set conf_path $plugin_path/conf.d
    for file in $conf_path/*.fish
        set -a unlink_files $file

        if test -n "$event"
            builtin emit (string replace $conf_path/ '' $file | string replace .fish _$event)
        end
    end

    set func_path $plugin_path/functions
    for file in $func_path/*.fish
        set -a unlink_files $file
        builtin functions -e (string replace $func_path/ '' $file | string replace .fish '')
    end

    for file in $plugin_path/completions/*.fish
        set -a unlink_files $file
    end

    for file in $unlink_files
        command rm (string replace $plugin_path $__fish_config_dir $file)
    end
end

function _plug_update -a plugin
    echo Updating $plugin
    set plugin_path $plug_path/$plugin
    command git -C $plugin_path fetch

    set local (command git -C $plugin_path rev-parse HEAD)
    set origin (command git -C $plugin_path rev-parse FETCH_HEAD)

    if test $local != $origin
        _plug_disable $plugin
        command git -C $plugin_path pull --rebase

        _plug_enable $plugin update
    end
end
