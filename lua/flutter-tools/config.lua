local M = {}

--- @param prefs table user preferences
local function validate_prefs(prefs)
  vim.validate {
    outline = {prefs.outline, "table", true},
    dev_log = {prefs.dev_log, "table", true},
    closing_tags = {prefs.closing_tags, "table", true}
  }
end

local config = {}

function M.get()
  return config
end

function M.set(user_config)
  -- we setup the defaults here so that dynamic values
  -- can be calculated as close as possible to usage
  local defaults = {
    dart_lookup_cmd = "which dart",
    flutter_lookup_cmd = "which flutter",
    flutter_outline = {
      highlight = "Normal",
      enabled = false
    },
    closing_tags = {
      highlight = "Comment",
      prefix = "//"
    },
    dev_log = {
      open_cmd = string.format("botright %dvnew", math.max(vim.o.columns * 0.4, 50))
    },
    outline = {
      open_cmd = string.format("botright %dvnew", math.max(vim.o.columns * 0.3, 40))
    }
  }

  config = user_config or {}
  validate_prefs(config)
  setmetatable(config, {__index = defaults})
end

return M
