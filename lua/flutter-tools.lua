local labels = require "flutter-tools/labels"
local outline = require "flutter-tools/outline"
local utils = require "flutter-tools/utils"
local commands = require "flutter-tools/commands"
local devices = require "flutter-tools/devices"
local dev_log = require "flutter-tools/dev_log"
local dev_tools = require "flutter-tools/dev_tools"
local lsp = require "flutter-tools/lsp"
local config = require "flutter-tools/config"

local M = {
  closing_tags = labels.closing_tags,
  outline = outline.document_outline,
  open_outline = outline.open,
  devices = devices.list_devices,
  emulators = devices.list_emulators,
  run = commands.run,
  pub_get = commands.pub_get,
  reload = dev_log.reload,
  restart = dev_log.restart,
  quit = dev_log.quit,
  visual_debug = dev_log.visual_debug,
  dev_tools = dev_tools.start,
  _resurrect_log = dev_log.resurrect
}

local function setup_commands()
  utils.command("FlutterRun", [[lua require('flutter-tools').run()]])
  utils.command("FlutterReload", [[lua require('flutter-tools').reload()]])
  utils.command("FlutterRestart", [[lua require('flutter-tools').restart()]])
  utils.command("FlutterQuit", [[lua require('flutter-tools').quit()]])
  utils.command("FlutterDevices", [[lua require('flutter-tools').devices()]])
  utils.command("FlutterEmulators", [[lua require('flutter-tools').emulators()]])
  utils.command("FlutterOutline", [[lua require('flutter-tools').open_outline()]])
  utils.command("FlutterDevTools", [[lua require('flutter-tools').dev_tools()]])
end

local function setup_autocommands()
  utils.augroup(
    "FlutterToolsHotReload",
    {
      {
        events = {"BufWritePost"},
        targets = {"*.dart"},
        command = "lua require('flutter-tools').reload(true)"
      },
      {
        events = {"BufWritePost"},
        targets = {"*/pubspec.yaml"},
        command = "lua require('flutter-tools').pub_get()"
      },
      {
        events = {"BufEnter"},
        targets = {dev_log.filename},
        command = "lua require('flutter-tools')._resurrect_log()"
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
