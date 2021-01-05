# flutter-tools.nvim

Tools to help create flutter apps in neovim using the native lsp

**Status: WIP**

# Inspiration

This plugin draws inspiration from [`coc-flutter`](https://github.com/iamcco/coc-flutter) and [`nvim-metals`](https://github.com/scalameta/nvim-metals), the idea being
to allow users to easily develop flutter apps using neovim.

## Installation

using `vim-plug`

```vim
Plug "neovim/nvim-lspconfig"
Plug "akinsho/flutter-tools.nvim"
```

or using `packer.nvim`

```lua
use {"akinsho/flutter-tools.nvim", requires = {"neovim/nvim-lspconfig"}}
```

Currently this plugin depends on `nvim-lspconfig` for some default setup this might change.
To set it up

```lua
flutter.setup_lsp {
  on_attach = my_custom_on_attach,
  capabilities = my_custom_capabilities -- e.g. lsp_status capabilities
}
```

You can override any options available in the `lspconfig` setup, this call essentially wraps
it and adds some extra `flutter` specific handlers and utilisation options.

You can also manually initialise the client and only and some handlers or options yourself.

```lua
local lspconfig = require('lspconfig')
local flutter = require('flutter-tools')
lspconfig.dartls.setup {
    flags = {allow_incremental_sync = true},
    init_options = {
    closingLabels = true,
    outline = true,
    flutterOutline = true
  },
  on_attach = on_attach,
  handlers = {
    ['dart/textDocument/publishClosingLabels'] = flutter.closing_tags,
    ['dart/textDocument/publishOutline'] = flutter.outline
  }
}
```

# Functionality

#### Run flutter app with hot reloading

![hot reload](./.github/hot_reload.gif)

#### Start emulators or connected devices

![device list](./.github/emulators.png)

#### Visualise logs

![dev log](./.github/dev_log.png)

#### Outline window

![Outline window](./.github/outline.gif)

#### Closing Tags

![closing tags](./.github/closing_tags.png)

# Usage

- `FlutterRun` - Run the current project. This needs to be run from within a flutter project.
- `FlutterDevices` - Brings up a list of connected devices to select from.
- `FlutterEmulators` - Similar to devices but shows a list of emulators to choose from.
- `FlutterReload` - Reload the running project
- `FlutterRestart` - Restart the current project
- `FlutterQuit` - Ends a running session
- `FlutterOutline` - Opens an outline window showing the widget tree for the given file

### TODO

- [ ] Connect + open devtools
- [ ] Close emulators and kill all processes on `VimLeave`
- [ ] Integrate with `nvim-dap`

- [x] Auto-scroll dev log
- [x] Add notification when restarting or reloading
- [x] LSP Outline window
- [x] LSP Closing Tags
