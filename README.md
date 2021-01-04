# flutter-tools.nvim

Tools to help create flutter apps in neovim using the native lsp

**This plugin is Very WIP at the moment**

# Inspiration

This plugin draws inspiration from [`coc-flutter`](https://github.com/iamcco/coc-flutter) and [`nvim-metals`](https://github.com/scalameta/nvim-metals), the idea being
to allow users to easily develop flutter apps using neovim.

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

- [ ] Auto-scroll dev log
- [ ] Connect + open devtools
- [ ] Close emulators and kill all processes on `VimLeave`

- [x] LSP Outline window
- [x] LSP Closing Tags
