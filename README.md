# 🐟🔌 Fish plug

Git-based [Fish](https://fishshell.com/) plugin manager.

> Fish plug is heavily infulenced by [Fisher](https://github.com/jorgebucaran/fisher). If you want a minimal alternative, check it out.

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
# From a local directory
plug install ~/my-plugin
# From any Git remote
plug install git@github.com:franciscolourenco/done.git
```

Fish plug uses the familiar `<author>/<name>` format for referencing plugins.

- When installing a plugin from local, it will be installed as `local/<directory>` as a symbolic link.

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
- `--pinned` / `-p` lists pinned plugins.
- `--unpinned` / `-u` lists unpinned plugins.
- `--source` / `-s` lists plugin's source (Git remote URL or local path). Useful for exporting a plugin list.
- `--verbose` / `-v` show plugin version (`git rev-parse --short`) and state (enabled/disabled)

### `plug enable <plugins>`

Enable specified plugins.

- This command is automatically executed during `plug install` (after cloning a plugin).
- Under the hood, Fish plug creates symbolic links for plugin files. This means changes of existing completions and functions in `$plug_path` are reflected in Fish without reloading.

### `plug disable <plugins>`

Disable specified plugins.

- This command is automatically executed during `plug uninstall` (before removing a plugin).

### `plug update/up [plugins]`

Update specified plugins.

- If no plugin is specified, all unpinned plugins will be updated.
- `--force` / `-f` will force update pinned plugins.

### `plug pin <plugins>`

Pin plugins. Pinned plugins won't be updated.

### `plug unpin <plugins>`

Unpin previously pinned plugins.

## Advanced

### Change `$plug_path`

Fish plug stores plugins in `$plug_path`, which is `$__fish_user_data_dir/plug` by default.

This can be changed before installation:

```sh
set -U plug_path ~/.fish-plug
# Install Fish plug
```

Or after installation:

```sh
set enabled_plugins (plug list --enabled)
plug disable $enabled_plugins
set new_plug_path ~/.fish-plug
mv $plug_path $new_plug_path
set -U plug_path $new_plug_path
_plug_enable $enabled_plugins
```

### Reload a plugin

If you have made changes to a plugin, you can reload it by `plug disable <plugin>`, then `plug enable <plugin>`.

### Accessing non-`.fish` files

Unlike Fisher, Fish plug doesn't copy non-`.fish` files in `functions`, `conf.d` and `completions`. However, you can access these files via `$plug_path`.

## Roadmap

- Install a specific version of plugin
- Capture environment variable changes when disabling plugins for recovering
