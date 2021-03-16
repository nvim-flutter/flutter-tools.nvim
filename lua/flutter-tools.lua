local utils = require("flutter-tools.utils")
local log = require("flutter-tools.log")
local lsp = require("flutter-tools.lsp")
local config = require("flutter-tools.config")

local M = {}

local function setup_commands()
  utils.command("FlutterRun", [[lua require('flutter-tools.commands').run()]])
  utils.command("FlutterReload", [[lua require('flutter-tools.log').reload()]])
  utils.command("FlutterRestart", [[lua require('flutter-tools.log').restart()]])
  utils.command("FlutterQuit", [[lua require('flutter-tools.log').quit()]])
  utils.command("FlutterDevices", [[lua require('flutter-tools.devices').list_devices()]])
  utils.command("FlutterEmulators", [[lua require('flutter-tools.devices').list_emulators()]])
  utils.command("FlutterOutline", [[lua require('flutter-tools.outline').open()]])
  utils.command("FlutterDevTools", [[lua require('flutter-tools.dev_tools').start()]])
  utils.command("FlutterVisualDebug", [[lua require('flutter-tools.log').visual_debug()]])
end

local function setup_autocommands()
  utils.augroup(
    "FlutterToolsHotReload",
    {
      {
        events = {"BufWritePost"},
        targets = {"*.dart"},
        command = "lua require('flutter-tools.log').reload(true)"
      },
      {
        events = {"BufWritePost"},
        targets = {"*/pubspec.yaml"},
        command = "lua require('flutter-tools.commands').pub_get()"
      },
      {
        events = {"BufEnter"},
        targets = {log.filename},
        command = "lua require('flutter-tools.log')._resurrect_log()"
      }
    }
  )
end

function M.setup(user_config)
  lsp.setup(config.set(user_config))
  setup_commands()
  setup_autocommands()
end

return M
