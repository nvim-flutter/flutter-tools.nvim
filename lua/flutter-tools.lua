local labels = require "flutter-tools/labels"
local utils = require "flutter-tools/utils"
local commands = require "flutter-tools/commands"
local emulators = require "flutter-tools/emulators"
local devices = require "flutter-tools/devices"
local dev_log = require "flutter-tools/dev_log"

local defaults = {
  closing_tags = {}
}

local M = {
  closing_tags = labels.closing_tags(defaults.closing_tags),
  devices = devices.list,
  emulators = emulators.list,
  run = commands.run,
  reload = dev_log.reload,
  restart = dev_log.restart,
  quit = dev_log.quit,
  visual_debug = dev_log.visual_debug
}

function M.setup(prefs)
  M.closing_tags = labels.closing_tags(prefs.closing_tags)
  utils.autocommands_create(
    {
      FlutterToolsHotReload = {
        {"BufWritePost", "*.dart", "lua require('flutter-tools').reload()"}
      }
    }
  )
end

return M
