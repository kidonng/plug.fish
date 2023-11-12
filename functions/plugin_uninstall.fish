function plugin_uninstall
    set --local plugins_dir $__fish_user_data_dir/plugins
    set --local enabled_plugins (path basename $plugins)

    for plugin_dir in $plugins_dir/*
        set --local plugin_name (path basename $plugin_dir)
        contains $plugin_name $enabled_plugins && continue

        read --local --nchars 1 --prompt-str "$plugin_name is disabled, uninstall? (y/N) " answer
        test (string lower $answer) = y || continue

        for conf in $plugin_dir/conf.d/*.fish
            emit (path basename $conf | path change-extension '')_uninstall
        end
        # `--force` needed for `.git` directory
        rm --recursive --force $plugin_dir

        echo Uninstalled (set_color --bold)$plugin_name(set_color normal)
    end
end
