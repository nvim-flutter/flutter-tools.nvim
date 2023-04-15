local lazy = require("flutter-tools.lazy")
local commands = lazy.require("flutter-tools.commands") ---@module "flutter-tools.commands"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local Path = require("plenary.path")

local M = {
  statusline = {},
}

local fn, api = vim.fn, vim.api

---Asynchronously read the data in the pubspec yaml and pass the results to a callback
---@param callback fun(data: string):nil
local function read_pubspec(callback)
  local root_patterns = { ".git", "pubspec.yaml" }
  local current_dir = fn.expand("%:p:h")
  local root_dir = path.find_root(root_patterns, current_dir) or current_dir
  local pubspec_path = path.join(root_dir, "pubspec.yaml")
  local pubspec = Path:new(pubspec_path)
  pubspec:read(callback)
end

---Add/update item to/in the decorations table
---@param key string
---@param value table
local function set_decoration_item(key, value)
  local decorations = vim.g.flutter_tools_decorations or {}
  decorations[key] = value
  vim.g.flutter_tools_decorations = decorations
end

local function device_show()
  local device = commands.current_device()
  if device then set_decoration_item("device", device) end
end

function M.statusline.device()
  api.nvim_create_autocmd("User", {
    pattern = utils.events.APP_STARTED,
    callback = device_show,
  })
end

local function app_version_show()
  read_pubspec(function(data)
    local lines = vim.split(data, "\n")
    for _, line in ipairs(lines) do
      if line:match("version:") then
        return set_decoration_item("app_version", "v" .. line:gsub("version: ", ""))
      end
    end
  end)
end

function M.statusline.app_version()
  -- show the version decoration immediately
  app_version_show()
  -- Refresh the statusline item when a user leaves the pubspec file
  api.nvim_create_autocmd({ "BufLeave", "BufWritePost" }, {
    pattern = { "pubspec.yaml" },
    callback = app_version_show,
  })
end

function M.statusline.project_config()
  api.nvim_create_autocmd("User", {
    pattern = utils.events.PROJECT_CONFIG_CHANGED,
    callback = function(args) set_decoration_item("project_config", args.data) end,
  })
end

---@param config table<string, table<string, boolean>>
function M.apply(config)
  if not config or vim.tbl_isempty(config) then return end
  for name, conf in pairs(config) do
    if M[name] and conf and type(conf) == "table" then
      for key, enabled in pairs(conf) do
        local func = M[name][key]
        if func and enabled then func() end
      end
    end
  end
end

return M
