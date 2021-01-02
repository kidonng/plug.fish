function plug -a cmd -d "Manage Fish plugins"
    test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug
    test -e $plug_path || command mkdir -p $plug_path

    switch "$cmd"
        case "" -h --help
            echo "Usage: plug install    <plugins>"
            echo "       plug uninstall  <plugins>"
            echo "       plug list       [-e | -d]"
            echo "       plug enable     <plugins>"
            echo "       plug disable    <plugins>"
            echo "       plug update     [plugins]"
            echo "       plug pin        <plugins>"
            echo "       plug unpin      <plugins>"
            echo "Options:"
            echo "       -h, --help    Show help message"
        case install add
            set plugins $argv[2..-1]
            set installed (_plug_list)

            for plugin in $plugins
                if builtin contains $plugin $installed
                    echo plug install: $plugin is already installed
                    continue
                end

                command fish -c (builtin functions _plug_install | string collect)" && _plug_install $plugin" &
            end

            wait

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
            set plugins $argv[2..-1]
            set installed (_plug_list)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo plug uninstall: $plugin is not installed
                    continue
                end

                _plug_disable $plugin uninstall
                _plug_uninstall $plugin
            end

            for author in $plug_path/*
                set author_plugins $author/*

                if test -z "$author_plugins"
                    command rm -d $author
                end
            end

            _plug_prompt

            if ! builtin functions -q plug
                command rm -d $plug_path
                set -e plug_path

                set functions install uninstall list enable disable update prompt
                builtin functions -e _plug_$functions
            end
        case list ls
            _plug_list $argv
        case enable
            set plugins $argv[2..-1]
            set installed (_plug_list)
            set enabled (_plug_list --enabled)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo plug enable: $plugin is not installed
                    continue
                end

                if builtin contains $plugin $enabled
                    echo plug enable: $plugin is already enabled
                    continue
                end

                _plug_enable $plugin install
            end
        case disable
            set plugins $argv[2..-1]
            set installed (_plug_list)
            set disabled (_plug_list --disabled)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo plug disable: $plugin is not installed
                    continue
                end

                if builtin contains $plugin $disabled
                    echo plug disable: $plugin is already disabled
                    continue
                end

                _plug_disable $plugin uninstall
            end

            _plug_prompt
        case update up
            argparse -n "plug update" f/force -- $argv || return

            set -q argv[2] || set -a argv (_plug_list --unpinned)
            set plugins $argv[2..-1]
            set installed (_plug_list)
            set pinned (_plug_list --pinned)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo plug update: $plugin is not installed
                    continue
                end

                if ! set -q _flag_force && builtin contains $plugin $pinned
                    echo plug update: $plugin is pinned
                    continue
                end

                command fish -c (builtin functions _plug_update | string collect)" && _plug_update $plugin" &
            end

            wait

            for plugin in (_plug_list --updated)
                set plugin_path $plug_path/$plugin
                set states_path $plugin_path/.git/fish-plug
                set updated_path $states_path/updated

                _plug_disable $plugin
                command git -C $plugin_path rebase -q FETCH_HEAD
                _plug_enable $plugin update
                command rm $updated_path
            end
        case pin
            set plugins $argv[2..-1]
            set installed (_plug_list)
            set pinned (_plug_list --pinned)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo plug pin: $plugin is not installed
                    continue
                end

                if builtin contains $plugin $pinned
                    echo plug pin: $plugin is already pinned
                    continue
                end

                set plugin_path $plug_path/$plugin
                set states_path $plugin_path/.git/fish-plug
                set pinned_path $states_path/pinned

                command touch $pinned_path
            end
        case unpin
            set plugins $argv[2..-1]
            set installed (_plug_list)
            set unpinned (_plug_list --unpinned)

            for plugin in $plugins
                if ! builtin contains $plugin $installed
                    echo plug unpin: $plugin is not installed
                    continue
                end

                if builtin contains $plugin $unpinned
                    echo plug unpin: $plugin is already unpinned
                    continue
                end

                set plugin_path $plug_path/$plugin
                set states_path $plugin_path/.git/fish-plug
                set pinned_path $states_path/pinned

                command rm $pinned_path
            end
        case \*
            echo plug: unknown command or option \"$cmd\" >&2
            return 1
    end
end

function _plug_install -a remote
    set truncated (string replace -r '(\.git)?/?$' '' $remote)

    if test -e $remote
        set plugin local/(string split / $truncated)[-1]
    else if string match -rq '^[\w.-]+/[\w.-]+$' $truncated
        set plugin $truncated
        set remote https://github.com/$remote
    else
        set plugin (string match -r '[\w.-]+/[\w.-]+$' $truncated)
    end

    echo plug install: installing $plugin "(from $remote)"

    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug

    command git clone -q $remote $plugin_path
    command mkdir -p $states_path
    command touch $states_path/updated
end

function _plug_uninstall -a plugin
    echo plug uninstall: uninstalling $plugin

    set plugin_path $plug_path/$plugin

    command rm -rf $plugin_path
end

function _plug_list
    argparse -n "plug list" e/enabled d/disabled x/updated p/pinned u/unpinned v/verbose -- $argv || return

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

        if set -q _flag_updated && ! builtin contains updated $states
            continue
        end

        if set -q _flag_pinned && ! builtin contains pinned $states
            continue
        end

        if set -q _flag_unpinned && builtin contains pinned $states
            continue
        end

        set info (string join / (string split / $plugin_path)[-2..-1])

        if set -q _flag_verbose
            if test (command git -C $plugin_path rev-parse --is-inside-work-tree) = true
                set -a info @(command git -C $plugin_path rev-parse --short HEAD)
            end

            if builtin contains disabled $states
                set -a info "#disabled"
            end

            if builtin contains pinned $states
                set -a info "#pinned"
            end
        end

        echo $info
    end
end

function _plug_enable -a plugin event
    echo plug enable: enabling $plugin

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
        command ln -si $file (string replace $plugin_path $__fish_config_dir $file)
    end

    if test -e $disabled_path
        command rm $disabled_path
    end
end

function _plug_disable -a plugin event
    echo plug disable: disabling $plugin

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
    echo plug update: updating $plugin

    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug
    set updated_path $states_path/updated

    command git -C $plugin_path fetch -q
    set local (command git -C $plugin_path rev-parse HEAD)
    set origin (command git -C $plugin_path rev-parse FETCH_HEAD)

    if test $local != $origin
        echo plug update: updated $plugin to (string sub -l 7 $origin) "(from "(string sub -l 7 $local)")"
        command touch $updated_path
    end
end

function _plug_prompt
    for prompt in fish_prompt fish_mode_prompt
        if ! builtin functions -q $prompt
            builtin source $__fish_data_dir/functions/$prompt.fish
        end
    end
end
