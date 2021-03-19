local utils = require("flutter-tools.utils")

local M = {}

local fmt = string.format

--- @param prefs table user preferences
local function validate_prefs(prefs)
  vim.validate {
    outline = {prefs.outline, "table", true},
    dev_log = {prefs.dev_log, "table", true},
    closing_tags = {prefs.closing_tags, "table", true}
  }
end

---Create a proportional split using a percentage specified as a float
---@param percentage number
---@param fallback number
---@return string
local function get_split_cmd(percentage, fallback)
  return string.format("botright %dvnew", math.max(vim.o.columns * percentage, fallback))
end

local defaults = {
  flutter_path = nil,
  flutter_lookup_cmd = utils.is_linux and "flutter sdk-path" or nil,
  widget_guides = {
    enabled = false
  },
  debugger = {
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

local deprecations = {
  flutter_outline = {
    fallback = "widget_guides",
    message = "please use 'widget_guides' instead"
  }
}

local function handle_deprecation(key, value, config)
  local deprecation = deprecations[key]
  if not deprecation then
    return
  end
  vim.defer_fn(
    function()
      utils.echomsg(fmt("%s is deprecated: %s", key, deprecation.message), "WarningMsg")
    end,
    1000
  )
  if deprecation.fallback then
    config[deprecation.fallback] = value
  end
end

local config = setmetatable({}, {__index = defaults})

function M.get()
  return config
end

function M.set(user_config)
  if not user_config or type(user_config) ~= "table" then
    return config
  end
  for key, value in pairs(user_config) do
    handle_deprecation(key, value, user_config)
  end
  validate_prefs(user_config)
  config = setmetatable(user_config, {__index = defaults})
  return config
end

return M
