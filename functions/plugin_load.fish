function plugin_load
    set --local dir $__fish_user_data_dir/plugins

    for plugin in $plugins
        set --local name (path basename $plugin)
        set --local plugin_dir $dir/$name

        set fish_complete_path \
            $fish_complete_path[1] \
            $plugin_dir/completions \
            $fish_complete_path[2..]
        set fish_function_path \
            $fish_function_path[1] \
            $plugin_dir/functions \
            $fish_function_path[2..]

        if test -e $plugin_dir
            for conf in $plugin_dir/conf.d/*.fish
                source $conf
            end
        else
            set_color --bold
            echo Installing $name
            set_color normal

            git clone --quiet --filter blob:none $plugin $plugin_dir

            for conf in $plugin_dir/conf.d/*.fish
                source $conf
                emit (path basename $conf | path change-extension '')_install
            end
        end
    end
end
