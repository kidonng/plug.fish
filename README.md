# 🐟🔌 plug.fish

[Fish](https://fishshell.com/) plugin manager, done right.

> **NOTE**: current default branch (`v2`) is a complete rewrite. Previous version is under `master` branch.

- Give `~/.config/fish` back to you
- Disable a plugin without uninstalling
- Pin a plugin to stop updating
- Support [Fisher plugin](https://github.com/jorgebucaran/fisher#creating-a-plugin)

## Motivation

[Fisher](https://github.com/jorgebucaran/fisher) is simple, reliable and proposed a wonderful event system for plugin authors. Inspired by Fisher, plug.fish was created with the following goals:

- `~/.config/fish` (`$__fish_config_dir`) is never used so it belongs to you
- Build on top of `$fish_complete_path` and `$fish_funciton_path` so plugins like [fishion](https://github.com/kidonng/fishion) are possible
- Proper [`conf.d` loading](https://github.com/fish-shell/fish-shell/blob/da32b6c172dcfe54c9dc4f19e46f35680fc8a91a/share/config.fish#L257-L269)

## Installation

1. Run following commands:

```fish
curl --silent --show-error --location https://raw.githubusercontent.com/kidonng/plug.fish/v2/functions/plug.fish | source
PLUG_GIT='--depth 1 -q --branch v2' plug install kidonng/plug.fish
```

2. Add the following commands to the top of `~/.config/fish/config.fish`:

```fish
if set --query plug_path
    source $plug_path/kidonng/plug.fish/functions/plug.fish
    plug init
end
```

## Usage

> **NOTE**: documentation is work in progress

Run `plug --help` to see available commands. Commands are self-evident and completions are available.

### Install plugins

The `plug install` command currently only supports installing from GitHub.

```fish
plug install jorgebucaran/spark.fish
```

To install plugins elsewhere, `git clone` them under `$plug_path/<namespace>/<plugin-name>` and enable them via `plug enable`.
