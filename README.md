# slime-enhanced.nvim

A Neovim plugin that enhances vim-slime with better tmux integration, Telescope-based target selection, and seamless pane switching capabilities.

https://github.com/user-attachments/assets/25c9530f-789d-4363-9f10-c41accefe83c

## Features

- 🚀 **Enhanced vim-slime integration** - Pre-configured settings with sensible defaults
- 🎯 **Telescope target picker** - Interactive selection of tmux sessions, windows, and panes
- 🔄 **Automatic pane switching** - Send code and automatically switch to target pane
- 📝 **Markdown code block support** - Send code blocks from markdown files
- ⚡ **Flexible cell delimiters** - Support for `# %%` cell markers and custom delimiters
- 🎛️ **Customizable keymaps** - Configure your preferred key bindings

## Requirements

- Neovim >= 0.7.0
- [vim-slime](https://github.com/jpalardy/vim-slime) plugin
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (for target picker functionality)
- tmux (for tmux integration)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "VenkatRaman3103/slime-enhanced.nvim",
  dependencies = {
    "jpalardy/vim-slime",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("slime-enhanced").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "VenkatRaman3103/slime-enhanced.nvim",
  requires = {
    "jpalardy/vim-slime",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("slime-enhanced").setup()
  end,
}
```

## Configuration

### Default Configuration

```lua
require("slime-enhanced").setup({
  target = "tmux",
  default_config = {
    socket_name = "default",
    target_pane = ":.1",
  },
  dont_ask_default = true,
  bracketed_paste = true,
  cell_delimiter = "# %%",
  keymaps = {
    send = "<leader>ss",
    send_cell_and_switch = "<leader>ro",
    send_cell_no_switch = "<leader>rr",
    pick_target = "<leader>rt",
  }
})
```

### Custom Configuration Example

```lua
require("slime-enhanced").setup({
  target = "tmux",
  default_config = {
    socket_name = "my-session",
    target_pane = ":.2",
  },
  cell_delimiter = "# %%",
  keymaps = {
    send = "<C-c><C-c>",
    send_cell_and_switch = "<leader>cr",
    send_cell_no_switch = "<leader>cc",
    pick_target = "<leader>cp",
  }
})
```

## Usage

### Basic Usage

1. **Send text/code**: Use `<leader>ss` (or your configured keymap) to send selected text or current line
2. **Send cell without switching**: Use `<leader>rr` to send the current code cell without switching panes
3. **Send cell and switch**: Use `<leader>ro` to send the current code cell and automatically switch to the target pane
4. **Pick target pane**: Use `<leader>rt` to open Telescope picker for selecting tmux target

### Code Cells

The plugin supports code cells using `# %%` delimiters by default:

```python
# %%
import numpy as np
x = np.array([1, 2, 3])
print(x)

# %%
y = x * 2
print(y)
```

### Markdown Support

In markdown files, the plugin automatically recognizes code blocks:

````markdown
Some text here...

```python
import pandas as pd
df = pd.DataFrame({'a': [1, 2, 3]})
print(df)
```

More text...
````

### Target Selection with Telescope

Use the pick target functionality (`<leader>rt`) to:

1. **Select Session**: Choose from available tmux sessions
2. **Select Window**: Pick a window within the selected session
3. **Select Pane**: Choose the specific pane to send code to

The interface provides a smooth, three-step selection process with clear prompts.

## Commands

The plugin provides several commands:

- `:SlimePickTarget` - Open Telescope picker for target selection
- `:SlimeSendCellNoSwitch` - Send current cell without switching panes
- `:SlimeSendAndSwitch` - Send current cell and switch to target pane

## Configuration Options

| Option             | Type    | Default                                          | Description                            |
| ------------------ | ------- | ------------------------------------------------ | -------------------------------------- |
| `target`           | string  | `"tmux"`                                         | Slime target backend                   |
| `default_config`   | table   | `{socket_name = "default", target_pane = ":.1"}` | Default tmux configuration             |
| `dont_ask_default` | boolean | `true`                                           | Skip prompts when using default config |
| `bracketed_paste`  | boolean | `true`                                           | Enable bracketed paste mode            |
| `cell_delimiter`   | string  | `"# %%"`                                         | Delimiter for code cells               |
| `keymaps`          | table   | See defaults above                               | Key mappings configuration             |

## Keymaps

| Keymap                 | Mode | Default      | Description                    |
| ---------------------- | ---- | ------------ | ------------------------------ |
| `send`                 | n, x | `<leader>ss` | Send text/selection            |
| `send_cell_and_switch` | n    | `<leader>ro` | Send cell and switch to target |
| `send_cell_no_switch`  | n    | `<leader>rr` | Send cell without switching    |
| `pick_target`          | n    | `<leader>rt` | Open target picker             |

## Tips

1. **Set up tmux panes**: Create your preferred tmux layout before using the plugin
2. **Use code cells**: Organize your code with `# %%` delimiters for easy cell-based execution
3. **Markdown workflows**: Great for sending code from documentation or notebooks
4. **Target switching**: Use the Telescope picker to quickly switch between different REPL sessions

## Troubleshooting

### Common Issues

**Telescope not found**: Make sure telescope.nvim is installed and loaded before this plugin.

**Target pane not responding**: Verify that the target tmux pane exists and is running an appropriate REPL (Python, R, etc.).

**Keymaps not working**: Check for conflicts with other plugins and ensure the plugin is properly loaded.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [vim-slime](https://github.com/jpalardy/vim-slime) - The core slime functionality
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - For the beautiful target picker interface
