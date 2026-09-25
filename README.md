# shmacs

A minimal terminal Emacs launcher. No init file, builtins only.

Source this file from Bash or paste it into your `.bashrc`.

For quick file edits and directory operations, without loading your usual config. Not intended to replace a full Emacs setup.

## Usage

| Command | Action |
| --- | --- |
| `e` | Open Emacs in a scratch buffer. |
| `e [file ...] [options]` | Open files or pass command-line options to Emacs. |
| `d` | Open Dired in the current directory (alias for `e .`). |
| `D` | Open two side-by-side Dired panes, like Midnight Commander. |
| `D [directory]` | Open two side-by-side Dired panes, with the supplied directory in the right-hand pane. |

## Terminal configuration

Some keybindings may need configuration in your terminal.

Example Ghostty settings (put these in Ghostty's config):

```ini
# Keybindings
keybind = ctrl+,=esc:b
keybind = ctrl+.=esc:f
keybind = ctrl+backspace=text:\x1b\x7f

# Optional cursor and notification preferences
app-notifications = no-clipboard-copy
cursor-color = #ffffff
cursor-text = #000000
cursor-style = block
shell-integration-features = no-cursor
```
