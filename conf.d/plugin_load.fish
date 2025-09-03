set --query _plugins_dir && exit

set --global _plugins_dir $__fish_user_data_dir/plugins
set --local user_conf (path basename $__fish_config_dir/conf.d/*.fish)

for plugin in $plugins
    set --local plugin_name (path basename $plugin)
    set --local plugin_dir $_plugins_dir/$plugin_name

    set fish_complete_path \
        $fish_complete_path[1] \
        $plugin_dir/completions \
        $fish_complete_path[2..]
    # Functions should be available before emitting events
    set fish_function_path \
        $fish_function_path[1] \
        $plugin_dir/functions \
        $fish_function_path[2..]

    test -e $plugin_dir || set --local install

    if set --query install
        echo Installing (set_color --bold)$plugin_name(set_color normal)

        git clone --quiet --filter blob:none $plugin $plugin_dir
    end

    for theme in $plugin_dir/themes/*.theme
        set --local theme_name (path basename $theme)
        set --local theme_dest $__fish_config_dir/themes/$theme_name

        test -d $__fish_config_dir/themes || mkdir -p $__fish_config_dir/themes

        cp $theme $theme_dest
    end

    for conf in $plugin_dir/conf.d/*.fish
        # Support masking
        contains (path basename $conf) $user_conf && continue

        source $conf
        set --query install && emit (path basename $conf | path change-extension '')_install
    end
end
