local labels = require "flutter-tools/labels"
local commands = require "flutter-tools/commands"
local dev_log = require "flutter-tools/dev_log"

local defaults = {
  closing_tags = {}
}

local M = {
  closing_tags = labels.closing_tags(defaults.closing_tags),
  devices = commands.get_devices,
  emulators = commands.get_emulators,
  run = commands.run,
  reload = dev_log.reload,
  restart = dev_log.restart,
  quit = dev_log.quit,
  visual_debug = dev_log.visual_debug
}

function M.setup(prefs)
  M.closing_tags = labels.closing_tags(prefs.closing_tags)
end

return M
