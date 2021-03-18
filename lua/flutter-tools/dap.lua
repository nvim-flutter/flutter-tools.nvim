local utils = require("flutter-tools.utils")
local executable = require("flutter-tools.executable")

local success, dap = pcall(require, "dap")
if not success then
  utils.echomsg({{"nvim-dap is not installed!\n", "Title"}, {dap, "ErrorMsg"}})
  return nil
end

local fn = vim.fn
local has = utils.executable
local fmt = string.format

local M = {}

local dart_code_git = "https://github.com/Dart-Code/Dart-Code.git"
local debugger_dir = utils.join {fn.stdpath("cache"), "dart-code"}
local debugger_path = utils.join {debugger_dir, "out", "dist", "debug.js"}

function M.install_debugger(silent)
  if fn.empty(fn.glob(debugger_dir)) <= 0 then
    if silent then
      return
    end
    return utils.echomsg(fmt("The debugger is already installed at %s", debugger_dir))
  end

  if not has("npx") or not has("git") then
    return utils.echomsg('You need "NPM" > 5.2.0 and "git" in order to install the debugger')
  end

  -- run install commands in a terminal
  vim.cmd [[15new]]
  local clone = fmt("git clone %s %s", dart_code_git, debugger_dir)
  local build = fmt("cd %s && npm install && npx webpack --mode development", debugger_dir)
  fn.termopen(fmt("%s && %s", clone, build))
end

function M.setup(user_config)
  local config = user_config and user_config.debugger or {}
  if config.enabled then
    M.install_debugger()
  end

  local flutter_sdk_path = executable.flutter_sdk_path
  local dart_sdk_path = executable.dart_sdk_root_path()

  dap.adapters.dart = {
    type = "executable",
    command = "node",
    args = {debugger_path, "flutter"}
  }
  dap.configurations.dart = {
    {
      type = "dart",
      request = "launch",
      name = "Launch flutter",
      dartSdkPath = dart_sdk_path,
      flutterSdkPath = flutter_sdk_path,
      program = "${workspaceFolder}/lib/main.dart",
      cwd = "${workspaceFolder}"
    }
  }
end

return M
