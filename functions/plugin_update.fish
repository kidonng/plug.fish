function plugin_update
    set --local dir $__fish_user_data_dir/plugins

    for plugin in $plugins
        set --local name (path basename $plugin)
        set --local plugin_dir $dir/$name

        set_color --bold
        echo Updating $name
        set_color normal

        git -C $plugin_dir pull --quiet
    end
end
