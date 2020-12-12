local labels = require "flutter-tools/labels"
local commands = require "flutter-tools/commands"

local defaults = {
  closing_tags = {}
}

local M = {
  closing_tags = labels.closing_tags(defaults.closing_tags),
  devices = commands.get_devices,
  emulators = commands.get_emulators,
  run = commands.run
}

function M.setup(prefs)
  M.closing_tags = labels.closing_tags(prefs.closing_tags)
end

return M
