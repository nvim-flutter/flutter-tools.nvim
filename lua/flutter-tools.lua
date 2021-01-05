local labels = require "flutter-tools/labels"
local outline = require "flutter-tools/outline"
local utils = require "flutter-tools/utils"
local commands = require "flutter-tools/commands"
local emulators = require "flutter-tools/emulators"
local devices = require "flutter-tools/devices"
local dev_log = require "flutter-tools/dev_log"
local lsp = require "flutter-tools/lsp"

local defaults = {
  closing_tags = {},
  outline = {
    open_cmd = "vnew"
  }
}

local M = {
  closing_tags = labels.closing_tags(defaults.closing_tags),
  outline = outline.document_outline(),
  open_outline = outline.open(defaults.outline),
  devices = devices.list,
  emulators = emulators.list,
  run = commands.run,
  pub_get = commands.pub_get,
  reload = dev_log.reload,
  restart = dev_log.restart,
  quit = dev_log.quit,
  visual_debug = dev_log.visual_debug,
  setup_lsp = lsp.setup,
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

--- @param prefs table user preferences
local function validate_prefs(prefs)
  vim.validate {
    open_cmd = {prefs.open_cmd, "string", true},
    closing_tags = {prefs.closing_tags, "table", true}
  }
end

function M.setup(prefs)
  validate_prefs(prefs)
  prefs = vim.tbl_deep_extend("keep", prefs, defaults)
  -- TODO figure out how to pass down user preferences
  M.closing_tags = labels.closing_tags(prefs.closing_tags)

  setup_commands()
  setup_autocommands()
end

return M
