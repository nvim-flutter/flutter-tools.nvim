local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")
local ui = require("flutter-tools.ui")

local success, dap = pcall(require, "dap")
if not success then
  ui.notify({ "nvim-dap is not installed!", dap }, { level = ui.ERROR })
  return
end

local fn = vim.fn
local has = utils.executable
local fmt = string.format

local M = {}

local dart_code_git = "https://github.com/Dart-Code/Dart-Code.git"
local debugger_dir = path.join(fn.stdpath("cache"), "dart-code")
local debugger_path = path.join(debugger_dir, "out", "dist", "debug.js")

---Install the dart code debugger into neovim’s cache directory
---@param silent boolean whether or not to warn if already installed
---@return nil
function M.install_debugger(silent)
  if vim.loop.fs_stat(debugger_path) then
    if silent then
      return
    end
    return ui.notify(
      { fmt("The debugger is already installed at %s", debugger_dir) },
      { level = ui.WARN }
    )
  end

  if not has("npx") or not has("git") then
    return ui.notify(
      { "You need npm > 5.2.0, npx and git in order to install the debugger" },
      ui.WARN
    )
  end

  -- run install commands in a terminal
  vim.cmd([[15new]])
  local clone = fmt("git clone %s %s", dart_code_git, debugger_dir)
  local build = fmt("cd %s && npm install && npx webpack --mode development", debugger_dir)
  fn.termopen(fmt("%s && %s", clone, build))
end

function M.setup(config)
  M.install_debugger(true)

  require("flutter-tools.executable").get(function(paths)
    dap.adapters.dart = {
      type = "executable",
      command = "node",
      args = { debugger_path, "flutter" },
    }
    config.debugger.register_configurations(paths)
  end)
end

return M
