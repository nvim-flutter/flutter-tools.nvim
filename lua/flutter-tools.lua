local utils = require("flutter-tools.utils")
local log = require("flutter-tools.log")
local lsp = require("flutter-tools.lsp")
local config = require("flutter-tools.config")

local M = {}

local function setup_commands()
  -- Commands
  utils.command("FlutterRun", [[lua require('flutter-tools.commands').run()]])
  utils.command("FlutterReload", [[lua require('flutter-tools.commands').reload()]])
  utils.command("FlutterRestart", [[lua require('flutter-tools.commands').restart()]])
  utils.command("FlutterQuit", [[lua require('flutter-tools.commands').quit()]])
  utils.command("FlutterVisualDebug", [[lua require('flutter-tools.commands').visual_debug()]])
  -- Lists
  utils.command("FlutterDevices", [[lua require('flutter-tools.devices').list_devices()]])
  utils.command("FlutterEmulators", [[lua require('flutter-tools.devices').list_emulators()]])
  --- Outline
  utils.command("FlutterOutline", [[lua require('flutter-tools.outline').open()]])
  --- Dev tools
  utils.command("FlutterDevTools", [[lua require('flutter-tools.dev_tools').start()]])
end

local function setup_autocommands()
  utils.augroup(
    "FlutterToolsHotReload",
    {
      {
        events = {"VimLeavePre"},
        targets = {"*"},
        command = "lua require('flutter-tools.devices').close_emulator()"
      },
      {
        events = {"BufWritePost"},
        targets = {"*.dart"},
        command = "lua require('flutter-tools.commands').reload(true)"
      },
      {
        events = {"BufWritePost"},
        targets = {"*/pubspec.yaml"},
        command = "lua require('flutter-tools.commands').pub_get()"
      },
      {
        events = {"BufEnter"},
        targets = {log.filename},
        command = "lua require('flutter-tools.log').__resurrect()"
      }
    }
  )
end

function M.setup(user_config)
  local conf = config.set(user_config)

  lsp.setup(conf)

  if conf.debugger.enabled then
    require("flutter-tools.dap").setup(conf)
  end

  setup_commands()
  setup_autocommands()
end

return M
