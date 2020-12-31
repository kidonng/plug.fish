# 🐟🔌 Fish plug

Git-based [Fish](https://fishshell.com/) plugin manager.

<small>Fish plug is heavily infulenced by <a href="https://github.com/jorgebucaran/fisher">Fisher</a>. If you want a minimal alternative, check it out.</small>

- Install, list, update and uninstall plugins, with concurrent cloning/fetching
- Disable and enable plugins
- Support [Fisher plugin](https://github.com/jorgebucaran/fisher#creating-a-plugin), including [event system](https://github.com/jorgebucaran/fisher#event-system)
- Fully based on Git and file system, simple yet hackable

## Installation

```sh
curl -sSL https://git.io/fish-plug | source && plug install kidonng/fish-plug
```

## Usage

### `plug install/add <plugins>`

Install specified plugins.

```sh
# From GitHub
plug install ilancosman/tide jorgebucaran/spark.fish
# From local Git repository
plug install ~/my-plugin
# From any Git remote
plug install git@github.com:franciscolourenco/done.git
```

Fish plug uses the familiar `<author>/<name>` format for referencing plugins.

- When installing a plugin from local, it will be installed as `local/<directory>`.

  In the example above, `~/my-plugin` will be installed as `local/my-plugin`.

- When installing a plugin from a Git remote, it will be installed as the last two parts of the remote separated by `/`.

  In the example above, `git@github.com:franciscolourenco/done.git` will be installed as `franciscolourenco/done`.

### `plug uninstall/rm <plugins>`

Uninstall specified plugins.

### `plug list/ls [filter]`

List plugins, applying specified filter.

- If no filter is specified, all installed plugins will be listed.
- `--enabled` / `-e` lists enabled plugins.
- `--disabled` / `-d` lists disabled plugins.
- `--verbose` / `-v` show plugin version (`git rev-parse --short`) and state (enabled/disabled)

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
- Install a specific version of plugin
- Pin and unpin plugin version
- Capture environment variable changes when disabling plugins for recovering
