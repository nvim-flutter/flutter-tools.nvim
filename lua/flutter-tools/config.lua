local utils = require("flutter-tools/utils")
local M = {}

--- @param prefs table user preferences
local function validate_prefs(prefs)
  vim.validate {
    outline = {prefs.outline, "table", true},
    dev_log = {prefs.dev_log, "table", true},
    closing_tags = {prefs.closing_tags, "table", true}
  }
end

local function get_split_cmd(percentage, fallback)
  return string.format("botright %dvnew", math.max(vim.o.columns * percentage, fallback))
end

local defaults = {
  flutter_path = nil,
  flutter_lookup_cmd = utils.is_linux and "flutter sdk-path" or nil,
  flutter_outline = {
    highlight = "Normal",
    enabled = false
  },
  closing_tags = {
    highlight = "Comment",
    prefix = "//"
  },
  outline = setmetatable(
    {},
    {
      __index = function(_, k)
        return k == "open_cmd" and get_split_cmd(0.3, 40) or nil
      end
    }
  ),
  dev_log = setmetatable(
    {},
    {
      __index = function(_, k)
        return k == "open_cmd" and get_split_cmd(0.4, 50) or nil
      end
    }
  ),
  experimental = {
    lsp_derive_paths = false
  }
}

local config = setmetatable({}, {__index = defaults})

function M.get()
  return config
end

function M.set(user_config)
  if not user_config or type(user_config) ~= "table" then
    return config
  end
  validate_prefs(user_config)
  config = setmetatable(user_config, {__index = defaults})
  return config
end

return M
