function plug -a cmd -d "Manage Fish plugins"
    test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug
    test -e $plug_path || command mkdir -p $plug_path
    set plugins $argv[2..-1]

    switch "$cmd"
        case "" -h --help
            echo "Usage: plug install    <plugins>"
            echo "       plug uninstall  <plugins>"
            echo "       plug list       [-e | -d]"
            echo "       plug enable     <plugins>"
            echo "       plug disable    <plugins>"
            echo "       plug update     [plugins]"
        case install add
            command mkdir -p $__fish_config_dir/{functions,conf.d,completions}

            for plugin in $plugins
                if builtin contains $plugin (_plug_list)
                    echo $plugin is already installed
                    continue
                end

                _plug_install $plugin
            end

            for plugin in (_plug_list --updated)
                set plugin_path $plug_path/$plugin
                set git_path $plugin_path/.git/fish-plug

                _plug_enable $plugin install
                command rm $git_path/updated
            end
        case uninstall rm
            for plugin in $plugins
                if ! builtin contains $plugin (_plug_list)
                    echo $plugin is not installed
                    continue
                end

                _plug_disable $plugin uninstall
                _plug_uninstall $plugin
            end

            for author in $plug_path/*
                set author_plugins $author/*

                if test -z "$author_plugins"
                    command rm -r $author
                end
            end

            _plug_prompt

            if ! builtin functions -q plug
                command rm -r $plug_path
                set -e plug_path

                for func in install uninstall list enable disable update prompt
                    builtin functions -e _plug_$func
                end
            end
        case list ls
            _plug_list $argv
        case enable
            for plugin in $plugins
                if ! builtin contains $plugin (_plug_list)
                    echo $plugin is not installed
                    continue
                end

                if builtin contains $plugin (_plug_list --enabled)
                    echo $plugin is already enabled
                    continue
                end

                _plug_enable $plugin install
            end
        case disable
            for plugin in $plugins
                if ! builtin contains $plugin (_plug_list)
                    echo $plugin is not installed
                    continue
                end

                if builtin contains $plugin (_plug_list --disabled)
                    echo $plugin is already disabled
                    continue
                end

                _plug_disable $plugin uninstall
            end

            _plug_prompt
        case update up
            set installed (_plug_list)
            test -z "$plugins" && set plugins $installed

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                _plug_update $plugin
            end

            for plugin in (_plug_list --updated)
                set plugin_path $plug_path/$plugin
                set git_path $plugin_path/.git/fish-plug

                _plug_disable $plugin
                command git -C $plugin_path rebase FETCH_HEAD
                _plug_enable $plugin update
                command rm $git_path/updated
            end
        case \*
            echo "plug: Unknown flag or command: \"$cmd\" (see `plug -h`)" >&2
            return 1
    end
end

function _plug_install -a plugin
    echo Cloning $plugin

    set plugin_path $plug_path/$plugin
    set git_path $plugin_path/.git/fish-plug

    command git clone -q https://github.com/$plugin $plugin_path
    command mkdir -p $git_path
    command touch $git_path/updated
end

function _plug_uninstall -a plugin
    echo Removing $plugin

    command rm -rf $plug_path/$plugin
end

function _plug_list
    argparse -n "plug list" e/enabled d/disabled u/updated -- $argv || return

    for plugin in $plug_path/*/*
        set git_path $plugin/.git/fish-plug
        set disabled_path $git_path/disabled
        set updated_path $git_path/updated

        if set -q _flag_enabled && test -e $disabled_path
            continue
        end

        if set -q _flag_disabled && ! test -e $disabled_path
            continue
        end

        if set -q _flag_updated && ! test -e $updated_path
            continue
        end

        string join / (string split / $plugin)[-2..-1]
    end
end

function _plug_enable -a plugin event
    echo Enabling $plugin

    set link_files
    set plugin_path $plug_path/$plugin
    set disabled $plugin_path/.git/fish-plug/disabled

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

    command rm -f $disabled
end

function _plug_disable -a plugin event
    echo Disabling $plugin

    set unlink_files
    set plugin_path $plug_path/$plugin
    set disabled $plugin_path/.git/fish-plug/disabled

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

    command touch $disabled
end

function _plug_update -a plugin
    echo Fetching $plugin

    set plugin_path $plug_path/$plugin
    set git_path $plugin_path/.git/fish-plug

    command git -C $plugin_path fetch -q
    set local (command git -C $plugin_path rev-parse HEAD)
    set origin (command git -C $plugin_path rev-parse FETCH_HEAD)

    if test $local != $origin
        echo Updating $plugin from (string sub -l 7 $local) to (string sub -l 7 $origin)
        command touch $git_path/updated
    end
end

function _plug_prompt
    if ! builtin functions -q fish_prompt
        builtin source $__fish_data_dir/functions/fish_prompt.fish
    end
end
