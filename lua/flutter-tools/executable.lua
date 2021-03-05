local config = require("flutter-tools/config")

local fn = vim.fn

local M = {}

---Fetch the path to the users flutter installation.
---NOTE: this should not be called before the plugin
---setup has occured
---@return string
function M.get_flutter()
  if M.path then
    return M.path
  end
  local c = config.get()
  if c.flutter_path then
    M.path = c.flutter_path
  elseif c.flutter_lookup_cmd then
    -- TODO the experience could be nicer if this
    -- ends up blocking for too long
    M.path = fn.system(c.lookup_cmd):gsub("[\n\r]", "")
  else
    M.path = fn.resolve(fn.exepath("flutter"))
  end
  return M.path
end

---Prefix a command with the flutter executable
---@param cmd string
function M.with(cmd)
  return M.get_flutter() .. " " .. cmd
end

return M
