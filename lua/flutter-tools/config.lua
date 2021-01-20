local M = {}

--- @param prefs table user preferences
local function validate_prefs(prefs)
  vim.validate {
    outline = {prefs.outline, "table", true},
    dev_log = {prefs.dev_log, "table", true},
    closing_tags = {prefs.closing_tags, "table", true}
  }
end

local defaults = {
  closing_tags = {
    highlight = "Comment",
    prefix = "//"
  },
  dev_log = {
    open_cmd = "botright 50vnew"
  },
  outline = {
    open_cmd = "botright 30vnew"
  }
}

local config = {}

function M.get()
  return config
end

function M.set(user_config)
  user_config = user_config or {}
  validate_prefs(user_config)
  config = vim.tbl_deep_extend("keep", user_config, defaults)
end

return M
