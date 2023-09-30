# 🐟🔌 plug.fish

[Fish](https://fishshell.com/) plugin manager, done right.

> **NOTE**: current default branch (`v2`) is a complete rewrite. Previous version is under `master` branch.

- Give `~/.config/fish` back to you
- Disable a plugin without uninstalling
- Pin a plugin to stop updating
- Support [Fisher plugin](https://github.com/jorgebucaran/fisher#creating-a-plugin)

## Installation

1. Run following commands:

```fish
curl --silent --show-error --location https://git.io/fish-plug | source
plug install kidonng/plug.fish
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
