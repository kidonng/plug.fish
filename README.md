# 🐟🔌 plug.fish

Git-based [Fish](https://fishshell.com/) plugin manager.

> plug.fish is heavily infulenced by [Fisher](https://github.com/jorgebucaran/fisher). If you want a minimal alternative, check it out.

- Manage plugins with concurrent updating and shell completions
- Beyond CRUD: disable a plugin or pin a plugin's update
- [Fisher plugin](https://github.com/jorgebucaran/fisher#creating-a-plugin) support, including [event system](https://github.com/jorgebucaran/fisher#event-system)
- Fully based on Git and file system, simple yet hackable

## Installation

Fish 3.2.0 or above is required.

- Use plug.fish ✨

  ```sh
  curl -sSL https://git.io/fish-plug | source && plug install kidonng/fish-plug
  ```

- Use Fisher

  ```sh
  fisher install kidonng/fish-plug
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

plug.fish adopts the familiar `<author>/<name>` format for referencing plugins.

- When installing a plugin from local, it will be installed as `local/<directory>` as a symbolic link.

  In the example above, `~/my-plugin` will be installed as `local/my-plugin`.

- When installing a plugin from a Git remote, it will be installed as the last two parts of the remote separated by `/`.

  In the example above, `git@github.com:franciscolourenco/done.git` will be installed as `franciscolourenco/done`.

### `plug uninstall/rm <plugins>`

Uninstall specified plugins.

### `plug list/ls [options]`

List plugins, using specified options.

- If no option is specified, all installed plugins will be listed.
- `--enabled` / `-e` lists enabled plugins.
- `--disabled` / `-d` lists disabled plugins.
- `--pinned` / `-p` lists pinned plugins.
- `--unpinned` / `-u` lists unpinned plugins.
- `--source` / `-s` lists each plugin's source (Git remote URL or local path). Useful for exporting a list of plugins.
- `--verbose` / `-v` shows plugin version (via `git rev-parse --short`) and states (disabled/pinned).

### `plug enable <plugins>`

Enable specified plugins.

- This command is automatically executed during `plug install` (after cloning a plugin).
- Under the hood, plug.fish creates symbolic links for plugin files. This means changes of existing completions and functions in `$plug_path` are reflected in Fish without reloading.

### `plug disable <plugins>`

Disable specified plugins.

- This command is automatically executed during `plug uninstall` (before removing a plugin).

### `plug update/up [plugins]`

Update specified plugins.

- If no plugin is specified, all unpinned plugins will be updated.
- `--force` / `-f` will force update pinned plugins.

### `plug pin <plugins>`

Pin plugins. Pinned plugins won't be updated.

- Local plugins are automatically pinned upon installing.

### `plug unpin <plugins>`

Unpin previously pinned plugins.

## Advanced

### Change `$plug_path`

plug.fish stores plugins in `$plug_path`, which is `$__fish_user_data_dir/plug` by default.

This can be changed before installation:

```sh
set -U plug_path ~/.plug.fish
# Install plug.fish
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

### Migrating from Fisher

plug.fish should provide the same compatibility as Fisher. The biggest differences between plug.fish and Fisher are Git based installation and absence of `fish_plugins`, the latter can be simulated with `plug list --source`.

plug.fish should be able to directly install plugins from a `fish_plugins` file:

```sh
# Save fish_plugins to somewhere else, and uninstall Fisher
plug install </path/to/fish_plugins
```

## Roadmap

- Error handling
- Better output (with color/emojies)
- Install a specific version of plugin
- Capture environment variable changes when disabling plugins for recovering
