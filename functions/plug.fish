function plug -a cmd -d "Manage Fish plugins"
    test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug
    test -e $plug_path || command mkdir -p $plug_path

    switch "$cmd"
        case "" -h --help
            echo "Usage: plug install    <plugins>"
            echo "       plug uninstall  <plugins>"
            echo "       plug list       [-edpuv]"
            echo "       plug enable     <plugins>"
            echo "       plug disable    <plugins>"
            echo "       plug update     [plugins]"
            echo "       plug pin        <plugins>"
            echo "       plug unpin      <plugins>"
            echo "Options:"
            echo "       -h, --help    Show help message"
        case install add
            set installed (_plug_list)
            set plug_install (builtin functions _plug_install | string collect)

            for raw in $argv[2..-1]
                if test -e $raw
                    set remote (realpath $raw)
                    set plugin local/(string split / $remote)[-1]
                else if string match -rq '^[\w.-]+/[\w.-]+$' $raw
                    set remote https://github.com/$raw
                    set plugin $raw
                else
                    set remote $raw
                    set plugin (string match -r '([\w.-]+/[\w.-]+?)(?:\.git|/)?$' $raw)[2]
                end

                if builtin contains $plugin $installed
                    echo plug install: $plugin is already installed
                    continue
                end

                command fish -c "$plug_install; _plug_install $plugin $remote" &
            end

            wait

            for dir in $__fish_config_dir/{completions,conf.d,functions}
                if ! test -e $dir
                    command mkdir -p $dir
                end
            end

            for plugin in (_plug_list --installed)
                _plug_enable $plugin install
            end
        case uninstall rm
            set installed (_plug_list)

            for plugin in $argv[2..-1]
                if ! builtin contains $plugin $installed
                    echo plug uninstall: $plugin is not installed
                    continue
                end

                _plug_disable $plugin uninstall
                _plug_uninstall $plugin
            end

            _plug_prompt

            for author in $plug_path/*
                set author_plugins $author/*

                if test -z "$author_plugins"
                    command rm -d $author
                end
            end

            if ! builtin functions -q plug
                command rm -d $plug_path
                set -e plug_path
                builtin functions -e _plug_{install,uninstall,list,enable,disable,update,prompt}
            end
        case list ls
            _plug_list $argv
        case enable
            set installed (_plug_list)
            set enabled (_plug_list --enabled)

            for plugin in $argv[2..-1]
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
            set installed (_plug_list)
            set disabled (_plug_list --disabled)

            for plugin in $argv[2..-1]
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
            set installed (_plug_list)
            set pinned (_plug_list --pinned)
            set plug_update (builtin functions _plug_update | string collect)

            for plugin in $argv[2..-1]
                if ! builtin contains $plugin $installed
                    echo plug update: $plugin is not installed
                    continue
                end

                if ! set -q _flag_force && builtin contains $plugin $pinned
                    echo plug update: $plugin is pinned
                    continue
                end

                command fish -c "$plug_update; _plug_update $plugin" &
            end

            wait

            for plugin in (_plug_list --updated)
                set plugin_path $plug_path/$plugin

                _plug_disable $plugin
                command git -C $plugin_path rebase -q FETCH_HEAD
                _plug_enable $plugin update
            end
        case pin
            set installed (_plug_list)
            set pinned (_plug_list --pinned)

            for plugin in $argv[2..-1]
                if ! builtin contains $plugin $installed
                    echo plug pin: $plugin is not installed
                    continue
                end

                if builtin contains $plugin $pinned
                    echo plug pin: $plugin is already pinned
                    continue
                end

                echo plug: pinning $plugin

                set plugin_path $plug_path/$plugin
                set states_path $plugin_path/.git/fish-plug
                set pinned_path $states_path/pinned

                command touch $pinned_path
            end
        case unpin
            set installed (_plug_list)
            set unpinned (_plug_list --unpinned)

            for plugin in $argv[2..-1]
                if ! builtin contains $plugin $installed
                    echo plug unpin: $plugin is not installed
                    continue
                end

                if builtin contains $plugin $unpinned
                    echo plug unpin: $plugin is already unpinned
                    continue
                end

                echo plug: unpinning $plugin

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

function _plug_install -a plugin remote
    echo plug: installing $plugin "(from $remote)"

    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug
    string match -q "local/*" $plugin && set local

    if set -q local
        set local_path $plug_path/local

        if ! test -e $local_path
            command mkdir -p $local_path
        end

        command ln -s $remote $plugin_path
    else
        command git clone -q $remote $plugin_path
    end

    command mkdir -p $states_path
    set states installed
    set -q local && set -a states pinned
    command touch $states_path/$states
end

function _plug_uninstall -a plugin
    echo plug: uninstalling $plugin

    set plugin_path $plug_path/$plugin

    command rm -rf $plugin_path
end

function _plug_list
    # TODO: Remove placeholder short flags after Fish 3.2
    # https://github.com/fish-shell/fish-shell/pull/7585
    argparse -n "plug list" e/enabled d/disabled p/pinned u/unpinned s/source v/verbose 1/installed 2/updated -- $argv || return

    for plugin_path in $plug_path/*/*
        set plugin (string split / $plugin_path)[-2..-1]
        set states_path $plugin_path/.git/fish-plug
        set states

        for state in $states_path/*
            set -a states (string replace $states_path/ "" $state)
        end

        if set -q _flag_enabled && builtin contains disabled $states;
            or set -q _flag_disabled && ! builtin contains disabled $states;
            or set -q _flag_pinned && ! builtin contains pinned $states;
            or set -q _flag_unpinned && builtin contains pinned $states;
            or set -q _flag_installed && ! builtin contains installed $states;
            or set -q _flag_updated && ! builtin contains updated $states
            continue
        end

        if set -q _flag_source || set -q _flag_verbose
            set source (realpath $plugin_path | string replace $HOME "~")
        end

        if set -q _flag_source
            if test $plugin[1] = local
                set info $source
            else
                set info (command git -C $plugin_path remote get-url origin)
            end
        else
            set info (string join / $plugin)
        end

        if set -q _flag_verbose
            if test $plugin[1] = local
                set -a info "->" $source
            else
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
    echo plug: enabling $plugin

    set plugin_path $plug_path/$plugin
    set comp_path $plugin_path/completions
    set conf_path $plugin_path/conf.d
    set func_path $plugin_path/functions
    set states_path $plugin_path/.git/fish-plug

    for file in {$comp_path,$conf_path,$func_path}/*.fish
        command ln -si $file (string replace $plugin_path $__fish_config_dir $file)
    end

    for file in {$func_path,$conf_path}/*.fish
        builtin source $file
    end

    for file in $conf_path/*.fish
        if test -n "$event"
            builtin emit (string replace -ra '^.*/|\.fish$' '' $file)_$event
        end
    end

    for state in $states_path/{disabled,installed,updated}
        if test -e $state
            command rm $state
        end
    end
end

function _plug_disable -a plugin event
    echo plug: disabling $plugin

    set plugin_path $plug_path/$plugin
    set comp_path $plugin_path/completions
    set conf_path $plugin_path/conf.d
    set func_path $plugin_path/functions
    set states_path $plugin_path/.git/fish-plug
    set disabled_path $states_path/disabled

    for file in $conf_path/*.fish
        if test -n "$event"
            builtin emit (string replace -ra '^.*/|\.fish$' '' $file)_$event
        end
    end

    for file in $func_path/*.fish
        builtin functions -e (string replace -ra '^.*/|\.fish$' '' $file)
    end

    for file in {$comp_path,$conf_path,$func_path}/*.fish
        command rm (string replace $plugin_path $__fish_config_dir $file)
    end

    command touch $disabled_path
end

function _plug_update -a plugin
    echo plug: updating $plugin

    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug
    set updated_path $states_path/updated

    command git -C $plugin_path fetch -q
    set local (command git -C $plugin_path rev-parse HEAD)
    set origin (command git -C $plugin_path rev-parse FETCH_HEAD)

    if test $local != $origin
        echo plug: updated $plugin to (string sub -l 7 $origin) "(from "(string sub -l 7 $local)")"
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
