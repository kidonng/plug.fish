function plug -a cmd -d "Manage Fish plugins"
    test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug
    test -e $plug_path || command mkdir -p $plug_path
    set plugins

    for arg in $argv[2..-1]
        if ! builtin contains -- $arg $plugins
            set -a plugins $arg
        end
    end

    switch "$cmd"
        case "" -h --help
            echo "Usage: plug install    <plugins>"
            echo "       plug uninstall  <plugins>"
            echo "       plug list       [-e | -d]"
            echo "       plug enable     <plugins>"
            echo "       plug disable    <plugins>"
            echo "       plug update     [plugins]"
            echo "Options:"
            echo "       -h, --help    Show help message"
        case install add
            set installed (_plug_list)

            for plugin in $plugins
                if builtin contains $plugin $installed
                    echo $plugin is already installed
                    continue
                end

                _plug_install $plugin
            end

            for dir in $__fish_config_dir/{completions,conf.d,functions}
                if ! test -e $dir
                    command mkdir -p $dir
                end
            end

            for plugin in (_plug_list --updated)
                set plugin_path $plug_path/$plugin
                set states_path $plugin_path/.git/fish-plug
                set updated_path $states_path/updated

                _plug_enable $plugin install
                command rm $updated_path
            end
        case uninstall rm
            set installed (_plug_list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
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

                set functions install uninstall list enable disable update prompt
                builtin functions -e _plug_$functions
            end
        case list ls
            _plug_list $argv
        case enable
            set installed (_plug_list)
            set enabled (_plug_list --enabled)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                if builtin contains $plugin $enabled
                    echo $plugin is already enabled
                    continue
                end

                _plug_enable $plugin install
            end
        case disable
            set installed (_plug_list)
            set disabled (_plug_list --disabled)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo $plugin is not installed
                    continue
                end

                if builtin contains $plugin $disabled
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
                set states_path $plugin_path/.git/fish-plug
                set updated_path $states_path/updated

                _plug_disable $plugin
                command git -C $plugin_path rebase FETCH_HEAD
                _plug_enable $plugin update
                command rm $updated_path
            end
        case \*
            echo plug: Unknown command or option \"$cmd\" >&2
            return 1
    end
end

function _plug_install -a plugin
    echo Cloning $plugin

    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug

    command git clone -q https://github.com/$plugin $plugin_path
    command mkdir -p $states_path
    command touch $states_path/updated
end

function _plug_uninstall -a plugin
    echo Removing $plugin

    set plugin_path $plug_path/$plugin

    command rm -rf $plugin_path
end

function _plug_list
    argparse -n "plug list" e/enabled d/disabled u/updated v/version -- $argv || return

    for plugin_path in $plug_path/*/*
        set states_path $plugin_path/.git/fish-plug
        set states $states_path/*

        if test -n "$states"
            set states (string replace $states_path/ "" $states)
        end

        if set -q _flag_enabled && builtin contains disabled $states
            continue
        end

        if set -q _flag_disabled && ! builtin contains disabled $states
            continue
        end

        if set -q _flag_updated && ! builtin contains updated $state
            continue
        end

        set info (string join / (string split / $plugin_path)[-2..-1])

        if set -q _flag_version
            set -a info (command git -C $plugin_path rev-parse --short HEAD)
        end

        if builtin contains disabled $states
            set -a info \(disabled\)
        end

        echo $info
    end
end

function _plug_enable -a plugin event
    echo Enabling $plugin

    set plugin_path $plug_path/$plugin
    set comp_path $plugin_path/completions
    set conf_path $plugin_path/conf.d
    set func_path $plugin_path/functions
    set states_path $plugin_path/.git/fish-plug
    set disabled_path $states_path/disabled
    set link_files

    for file in $func_path/*.fish
        set -a link_files $file
        builtin source $file
    end

    for file in $conf_path/*.fish
        set -a link_files $file
        builtin source $file

        if test -n "$event"
            builtin emit (string replace -r "$conf_path/(\w+)\.fish" "\$1_$event" $file)
        end
    end

    for file in $comp_path/*.fish
        set -a link_files $file
    end

    for file in $link_files
        command ln -s $file (string replace $plugin_path $__fish_config_dir $file)
    end

    if test -e $disabled_path
        command rm $disabled_path
    end
end

function _plug_disable -a plugin event
    echo Disabling $plugin

    set plugin_path $plug_path/$plugin
    set comp_path $plugin_path/completions
    set conf_path $plugin_path/conf.d
    set func_path $plugin_path/functions
    set states_path $plugin_path/.git/fish-plug
    set disabled_path $states_path/disabled
    set unlink_files

    for file in $conf_path/*.fish
        set -a unlink_files $file

        if test -n "$event"
            builtin emit (string replace -r "$conf_path/(\w+)\.fish" "\$1_$event" $file)
        end
    end

    for file in $func_path/*.fish
        set -a unlink_files $file
        builtin functions -e (string replace -r "$func_path/(\w+)\.fish" '$1' $file)
    end

    for file in $comp_path/*.fish
        set -a unlink_files $file
    end

    for file in $unlink_files
        command rm (string replace $plugin_path $__fish_config_dir $file)
    end

    command touch $disabled_path
end

function _plug_update -a plugin
    echo Fetching $plugin

    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug
    set updated_path $states_path/updated

    command git -C $plugin_path fetch -q
    set local (command git -C $plugin_path rev-parse HEAD)
    set origin (command git -C $plugin_path rev-parse FETCH_HEAD)

    if test $local != $origin
        echo Updating $plugin from (string sub -l 7 $local) to (string sub -l 7 $origin)
        command touch $updated_path
    end
end

function _plug_prompt
    if ! builtin functions -q fish_prompt
        builtin source $__fish_data_dir/functions/fish_prompt.fish
    end
end
