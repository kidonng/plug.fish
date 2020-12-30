# 🐟🔌 Fish plug

Git-based [Fish](https://fishshell.com/) plugin manager.

<small>

The design of Fish plug is heavily based on [Fisher](https://github.com/jorgebucaran/fisher). If you want a minimal plugin manager, check it out.

</small>

- Install, list, update and uninstall plugins
- Enable or disable plugins
- [Fisher plugin](https://github.com/jorgebucaran/fisher#creating-a-plugin) support, including [event system](https://github.com/jorgebucaran/fisher#event-system)
- Based on Git, easy to hack

## Installation

```sh
curl -sSL https://git.io/fish-plug | source && plug install kidonng/fish-plug
```

## Usage

<small>

Currently, Fish plug only supports plugins from GitHub. You can install it along with another plugin manager (such as Fisher) to manage other unsupported plugins.

</small>

### `plug install/add <plugins>`

Install specified plugins.

Currently Fish plug supports `<GitHub user>/<repository name>` format:

```sh
plug install ilancosman/tide franciscolourenco/done
```

### `plug uninstall/rm <plugins>`

Uninstall specified plugins.

### `plug list/ls [filter]`

List plugins, applying specified filter.

- If no filter is specified, all installed plugins will be listed.
- `--enabled` / `-e` lists enabled plugins.
- `--disabled` / `-d` lists disabled plugins.

### `plug enable <plugins>`

Enable specified plugins.

- This command is automatically executed during `plug install` (after cloning a plugin).

### `plug disable <plugins>`

Disable specified plugins.

- This command is automatically executed during `plug uninstall` (before removing a plugin).

### `plug update/up [plugins]`

Update specified plugins.

- If no plugin is specified, all plugins will be updated.

## Advanced

### `$plug_path`

Fish plug stores plugins in `$plug_path`, which is `$__fish_user_data_dir/plug` by default. This can be changed before or after installation.

### Reload a plugin

If you have made changes to a plugin in `$plug_path`, you can reload it by `plug disable`, then `plug enable`.

### Soft links

Fish plug uses soft links (`ln -s`) instead of copying. This has several benefits:

- Changes in `$plug_path` are reflected in Fish without reloading, convenient for manual editing and Git checkout
- Easier to differentiate with files not managed by Fish plug

### Accessing on-`.fish` files

Unlike Fisher, Fish plug doesn't copy non-`.fish` files in `functions`, `conf.d` and `completions`. However, you can access these files via `$plug_path`.

## Roadmap

- `plug enable --reload`
- Install from other remote or local
- Install a specific version of plugin
- Pin and unpin plugin version
- Capture environment variable changes when disabling plugins for recovering
- Concurrent installing/updating
