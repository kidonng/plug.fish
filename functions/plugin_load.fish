function plugin_load
    set --local plugins_dir $__fish_user_data_dir/plugins
    set --local user_conf (path basename $__fish_config_dir/conf.d/*.fish)

    for plugin in $plugins
        set --local plugin_name (path basename $plugin)
        set --local plugin_dir $plugins_dir/$plugin_name

        set fish_complete_path \
            $fish_complete_path[1] \
            $plugin_dir/completions \
            $fish_complete_path[2..]
        # Functions should be available before emitting events
        set fish_function_path \
            $fish_function_path[1] \
            $plugin_dir/functions \
            $fish_function_path[2..]

        if test -e $plugin_dir
            for conf in $plugin_dir/conf.d/*.fish
                # Support masking
                if ! contains (path basename $conf) $user_conf
                    source $conf
                end
            end
        else
            set_color --bold
            echo Installing $plugin_name
            set_color normal

            git clone --quiet --filter blob:none $plugin $plugin_dir

            for conf in $plugin_dir/conf.d/*.fish
                source $conf
                emit (path basename $conf | path change-extension '')_install
            end
        end
    end
end
