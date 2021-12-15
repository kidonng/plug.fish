test -z "$plug_path" && set -U plug_path $__fish_user_data_dir/plug

function plug -a cmd -d "Manage Fish plugins"
    isatty || read -az stdin && set -a argv $stdin
    set plugins (string match -v -- "-*" $argv[2..])

    function _plug_require_state -a state -V plugins
        test -z "$plugins" && return

        set state_plugins (_plug_list --$state)
        test -z "$state" && set state installed

        for plugin in $plugins
            if ! contains $plugin $state_plugins
                echo (set_color red)plug: (set_color -o)$plugin(set_color normal)(set_color red) is not $state(set_color normal) >&2
                return 1
            end
        end
    end

    if test "$cmd" != install && test "$cmd" != add
        _plug_require_state || return 1
    end

    switch "$cmd"
        case "" -h --help
            printf "%s\n" \
                "Usage: plug install    <plugins>" \
                "       plug uninstall  <plugins>" \
                "       plug list       [options]" \
                "       plug enable     <plugins>" \
                "       plug disable    <plugins>" \
                "       plug update     [plugins]" \
                "       plug pin        <plugins>" \
                "       plug unpin      <plugins>" \
                "Options:" \
                "       -h, --help    Show help message"
        case install add
            for dir in $__fish_config_dir/{completions,conf.d,functions}
                if ! test -e $dir
                    mkdir -p $dir
                end
            end

            set installed (_plug_list)
            set plug_install (functions _plug_install | string collect)

            for raw in $plugins
                if string match -rq '^[\w.-]+/[\w.-]+$' $raw
                    set remote https://github.com/$raw
                    set plugin $raw
                else if test -e $raw
                    set remote (realpath $raw)
                    set plugin local/(string split / $remote)[-1]
                else
                    set remote $raw
                    set plugin (string match -r '([\w.-]+/[\w.-]+?)(?:\.git|/)?$' $raw)[2]
                end

                if contains $plugin $installed
                    echo (set_color red)plug:(set_color -o) $plugin(set_color normal)(set_color red) is already installed(set_color normal) >&2
                    return 1
                end

                echo plug: installing (set_color -o)$plugin(set_color normal) from (set_color -o)$remote(set_color normal)
                fish -c "$plug_install; _plug_install $plugin $remote" &
            end

            wait

            for plugin in (_plug_list --installed)
                echo plug: enabling (set_color -o)$plugin(set_color normal)
                _plug_enable $plugin install
                rm $plug_path/$plugin/.git/fish-plug/installed
            end
        case uninstall rm
            set disabled (_plug_list --disabled)

            for plugin in $plugins
                if ! contains $plugin $disabled
                    echo plug: disabling (set_color -o)$plugin(set_color normal)
                    _plug_disable $plugin uninstall
                end

                echo plug: uninstalling (set_color -o)$plugin(set_color normal)
                _plug_uninstall $plugin
            end

            _plug_prompt

            if ! functions -q plug
                rm -d $plug_path
                set -e plug_path
                functions -e _plug_{install,uninstall,list,enable,disable,update,prompt,require_state}
            end
        case list ls
            _plug_list $argv
        case enable
            _plug_require_state disabled || return 1

            for plugin in $plugins
                echo plug: enabling (set_color -o)$plugin(set_color normal)
                _plug_enable $plugin install
            end
        case disable
            _plug_require_state enabled || return 1

            for plugin in $plugins
                echo plug: disabling (set_color -o)$plugin(set_color normal)
                _plug_disable $plugin uninstall
            end

            _plug_prompt
        case update up
            _plug_require_state unpinned || return 1
            _plug_require_state remote || return 1

            test -z "$plugins" && set plugins (_plug_list --unpinned --remote)
            set plug_update (functions _plug_update | string collect)

            for plugin in $plugins
                echo plug: updating (set_color -o)$plugin(set_color normal)
                fish -c "$plug_update; _plug_update $plugin" &
            end

            wait

            for plugin in (_plug_list --updated)
                set plugin_path $plug_path/$plugin

                _plug_disable $plugin

                git -C $plugin_path rebase -q FETCH_HEAD

                _plug_enable $plugin update

                rm $plugin_path/.git/fish-plug/updated
            end
        case pin
            _plug_require_state unpinned || return 1

            for plugin in $plugins
                echo plug: pinning (set_color -o)$plugin(set_color normal)

                true >$plug_path/$plugin/.git/fish-plug/pinned
            end
        case unpin
            _plug_require_state pinned || return 1

            for plugin in $plugins
                echo plug: unpinning (set_color -o)$plugin(set_color normal)

                rm $plug_path/$plugin/.git/fish-plug/pinned
            end
        case "*"
            echo (set_color red)plug: unknown command or option (set_color -o)$cmd(set_color normal) >&2
            return 1
    end
end

function _plug_install -a plugin remote
    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug
    set states installed disabled

    if string match -q "local/*" $plugin
        set local_path $plug_path/local

        if ! test -e $local_path
            mkdir -p $local_path
        end

        ln -si $remote $plugin_path
    else
        git clone --depth 1 -q $remote $plugin_path
    end

    mkdir -p $states_path
    eval true ">"$states_path/$states
end

function _plug_uninstall -a plugin
    set plugin_path $plug_path/$plugin

    rm -rf $plugin_path

    set author (string split -f 1 / $plugin)
    set author_path $plug_path/$author

    if test (count $author_path/*) = 0
        rm -d $author_path
    end
end

function _plug_list
    argparse -n "plug list" e/enabled d/disabled p/pinned u/unpinned s/source v/verbose installed updated remote -- $argv || return

    for plugin_path in $plug_path/*/*
        set plugin (string split / $plugin_path)[-2..]
        set states_path $plugin_path/.git/fish-plug
        set states

        for state in $states_path/*
            set -a states (string replace $states_path/ "" $state)
        end

        if set -q _flag_enabled && contains disabled $states;
            or set -q _flag_disabled && ! contains disabled $states;
            or set -q _flag_pinned && ! contains pinned $states;
            or set -q _flag_unpinned && contains pinned $states;
            or set -q _flag_installed && ! contains installed $states;
            or set -q _flag_updated && ! contains updated $states
            or set -q _flag_remote && test $plugin[1] = local
            continue
        end

        if set -q _flag_source || set -q _flag_verbose
            set source (realpath $plugin_path | string replace $HOME "~")
        end

        if set -q _flag_source
            if test $plugin[1] = local
                set info $source
            else
                set info (git -C $plugin_path remote get-url origin)
            end
        else
            set info (string join / $plugin)
        end

        if set -q _flag_verbose
            if set -q _flag_verbose
                set info (echo (set_color -o)$info(set_color normal))
            end

            if test $plugin[1] = local
                if ! set -q _flag_source
                    set -a info "->" $source
                end
            else
                set -a info @(git -C $plugin_path rev-parse --short HEAD)
            end

            if contains disabled $states
                set -a info "#disabled"
            end

            if contains pinned $states
                set -a info "#pinned"
            end
        end

        echo $info
    end
end

function _plug_enable -a plugin event
    set plugin_path $plug_path/$plugin
    set comp_path $plugin_path/completions
    set conf_path $plugin_path/conf.d
    set func_path $plugin_path/functions

    for file in {$comp_path,$conf_path,$func_path}/*
        ln -si $file (string replace $plugin_path $__fish_config_dir $file)
    end

    for file in {$func_path,$conf_path}/*.fish
        source $file
    end

    if test -n "$event"
        for file in $conf_path/*.fish
            emit (string replace -ra '^.*/|\.fish$' '' $file)_$event
        end
    end

    rm $plugin_path/.git/fish-plug/disabled
end

function _plug_disable -a plugin event
    set plugin_path $plug_path/$plugin
    set comp_path $plugin_path/completions
    set conf_path $plugin_path/conf.d
    set func_path $plugin_path/functions

    if test -n "$event"
        for file in $conf_path/*.fish
            emit (string replace -ra '^.*/|\.fish$' '' $file)_$event
        end
    end

    for file in $func_path/*.fish
        functions -e (string replace -ra '^.*/|\.fish$' '' $file)
    end

    for file in {$comp_path,$conf_path,$func_path}/*
        rm (string replace $plugin_path $__fish_config_dir $file)
    end

    true >$plugin_path/.git/fish-plug/disabled
end

function _plug_update -a plugin
    set plugin_path $plug_path/$plugin
    set states_path $plugin_path/.git/fish-plug

    git -C $plugin_path fetch -q
    set local (git -C $plugin_path rev-parse HEAD)
    set origin (git -C $plugin_path rev-parse FETCH_HEAD)

    if test $local != $origin
        echo plug: updated (set_color -o)$plugin(set_color normal) from (set_color -o)(string sub -l 7 $local)(set_color normal) to (set_color -o)(string sub -l 7 $origin)(set_color normal)

        if test -e $states_path/disabled
            git -C $plugin_path rebase -q FETCH_HEAD
        else
            true >$states_path/updated
        end
    end
end

function _plug_prompt
    for prompt in fish_{,mode_}prompt
        if ! functions -q $prompt
            source $__fish_data_dir/functions/$prompt.fish
        end
    end
end
