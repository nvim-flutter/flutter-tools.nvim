local labels = require "flutter-tools/labels"

local defaults = {
  closing_tags = {}
}

local M = {
  closing_tags = labels.closing_tags(defaults.closing_tags)
}

function M.setup(prefs)
  M.closing_tags = labels.closing_tags(prefs.closing_tags)
end

return M
