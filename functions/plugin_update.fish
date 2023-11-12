function plugin_update
    set --local plugins_dir $__fish_user_data_dir/plugins

    for plugin in $plugins
        set --local plugin_name (path basename $plugin)
        set --local plugin_dir $plugins_dir/$plugin_name

        set_color --bold
        echo Updating $plugin_name
        set_color normal

        git -C $plugin_dir pull --quiet
    end
end
