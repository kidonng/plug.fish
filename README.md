# plug.fish

Minimalistic Git-based fish plugin manager.

## Features

- Doesn't occupy `~/.config/fish`
- Flexible plugin management
- Support [Fisher plugins](https://github.com/jorgebucaran/fisher#creating-a-plugin)
- < 100 lines of code you can actually read and understand

## Requirements

- fish >= 3.5
- Git

## Installation

1. Run this one-liner:

```fish
curl -L https://l0c.cc/plug.fish | plugins=https://github.com/kidonng/plug.fish source
```

2. Add the following to your `~/.config/fish/config.fish`

```fish
set plugins https://github.com/kidonng/plug.fish
source $__fish_user_data_dir/plugins/conf.d/plugin_load.fish
```

## Usage

Adding plugins is as easy as setting `$plugins`:

```fish
# Missing plugins are downloaded the next shell session
set plugins \
	https://github.com/kidonng/plug.fish \
    https://github.com/other/plugin \
	~/any/git/repository
```

Update plugins by running `plugin_update`:

```shellsession
$ plugin_update
Updating example-plugin
Updating another-plugin
```

Don't want some plugin to update? Add it to `$plugins_pinned`:

```fish
set plugins \
	https://github.com/kidonng/plug.fish \
    https://github.com/plugin/to-be-pinned
# Use the last segment as identifier 
set plugins_pinned to-be-pinned
```

Not into some plugin? Remove it from `$plugins` to disable it or even run `plugin_uninstall`:

```shellsession
$ plugin_uninstall
example-plugin is disabled, uninstall? (y/N)
```

## Advanced

### Manage plugins from the command-line

Don't like editing config files? Make `$plugins` a [universal variable](https://fishshell.com/docs/current/language.html#variables-universal) and `set` becomes a plugin manager:

```shellsession
$ set --universal plugins \
	https://github.com/kidonng/plug.fish \
    https://github.com/plugin/foo

$ # Add plugin bar
$ set --append plugins https://github.com/plugin/bar && exec fish

$ # Remove plugin foo
$ set --erase plugins[2] && plugin_uninstall
```

### Load plugins dynamically

Edit `~/.config/fish/config.fish`:

```diff
- set plugins \
+ set --query plugins || set plugins \
	https://github.com/kidonng/plug.fish \
    https://github.com/plugin/foo \
    https://github.com/plugin/bar
```

Now you are able to load plugins however you want:

```fish
# Only the first two plugins will be loaded in the new shell!
plugins=$plugins[..2] exec fish
```

### Masking `conf.d` scripts

Creating `~/.config/fish/conf.d/foo.fish` prevents loading `some-plugin/conf.d/foo.fish` (masking).

This is per the behavior described in [fish documentation](https://fishshell.com/docs/current/language.html#configuration-files):

> If there are multiple files with the same name in these directories, only the first will be executed.
