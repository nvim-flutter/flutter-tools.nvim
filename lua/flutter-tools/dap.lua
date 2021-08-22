local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")

local success, dap = pcall(require, "dap")
if not success then
  utils.notify("nvim-dap is not installed!\n" .. dap, utils.L.ERROR)
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
    return utils.notify(fmt("The debugger is already installed at %s", debugger_dir), utils.L.ERROR)
  end

  if not has("npx") or not has("git") then
    return utils.notify(
      "You need npm > 5.2.0, npx and git in order to install the debugger",
      utils.L.WARN
    )
  end

  -- run install commands in a terminal
  vim.cmd([[15new]])
  local clone = fmt("git clone %s %s", dart_code_git, debugger_dir)
  local build = fmt("cd %s && npm install && npx webpack --mode development", debugger_dir)
  fn.termopen(fmt("%s && %s", clone, build))
end

function M.setup(_)
  M.install_debugger(true)

  require("flutter-tools.executable").get(function(paths)
    dap.adapters.dart = {
      type = "executable",
      command = "node",
      args = { debugger_path, "flutter" },
    }
    dap.configurations.dart = {
      {
        type = "dart",
        request = "launch",
        name = "Launch flutter",
        dartSdkPath = paths.dart_sdk,
        flutterSdkPath = paths.flutter_sdk,
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
      },
      {
        type = "dart",
        request = "attach",
        name = "Connect flutter",
        dartSdkPath = paths.dart_sdk,
        flutterSdkPath = paths.flutter_sdk,
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
      },
    }
  end)
end

return M
