local lazy = require("flutter-tools.lazy")
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"

---@class flutter.ProjectConfig
---@field name? string
---@field device? string
---@field pre_run_callback? fun(opts: {string: string})
---@field flavor? string
---@field target? string
---@field dart_define? {[string]: string}
---@field dart_define_from_file? string
---@field flutter_mode? string
---@field web_port? string
---@field cwd? string full path of current working directory, defaults to LSP root
---@field additional_args? string[] additional arguments to pass to the flutter run command
---
---@class flutter.DevLogOpts
---@field filter? fun(data: string): boolean
---@field enabled? boolean
---@field notify_errors? boolean
---@field focus_on_open? boolean
---@field open_cmd? string
---
---@class flutter.RunArgsOpts
---@field flutter? table|string -- options applied to `flutter run` command
---@field dart? table|string -- options appliert to `dart run` command
---
---@class flutter.Config
---@field flutter_path? string Path to the Flutter SDK
---@field flutter_lookup_cmd? string Command to find Flutter SDK
---@field pre_run_callback? fun(opts: table) Function called before running Flutter
---@field root_patterns? string[] Patterns to find project root
---@field fvm? boolean Whether to use FVM (Flutter Version Manager)
---@field default_run_args? flutter.RunArgsOpts Default options for run command
---@field widget_guides? {enabled: boolean, debug: boolean}
---@field ui? {border: string}
---@field decorations? {statusline: {app_version: boolean, device: boolean, project_config: boolean}}
---@field debugger? {enabled: boolean, exception_breakpoints?: table, evaluate_to_string_in_debug_views?: boolean, register_configurations?: fun(paths: table)}
---@field closing_tags? {highlight: string, prefix: string, priority: number, enabled: boolean}
---@field lsp? {debug?: number, color?: {enabled: boolean, background: boolean, foreground: boolean, virtual_text: boolean, virtual_text_str: string, background_color?: string}, settings?: table}
---@field outline? {auto_open: boolean, open_cmd?: string}
---@field dev_log? flutter.DevLogOpts
---@field dev_tools? {autostart: boolean, auto_open_browser: boolean}
---@field analyzer_web_port? number

local M = {}

---@type flutter.ProjectConfig[]
local project_config = {}

local fn = vim.fn
local fmt = string.format

--- @param prefs table user preferences
local function validate_prefs(prefs)
  if prefs.flutter_path and prefs.flutter_lookup_cmd then
    vim.schedule(
      function()
        ui.notify(
          'Only one of "flutter_path" and "flutter_lookup_cmd" are required. Please remove one of the keys',
          ui.ERROR
        )
      end
    )
  end
  if vim.fn.has("nvim-0.11") == 1 then
    vim.validate("outline", prefs.outline, "table", true)
    vim.validate("dev_log", prefs.dev_log, "table", true)
    vim.validate("closing_tags", prefs.closing_tags, "table", true)
  else
    vim.validate({
      outline = { prefs.outline, "table", true },
      dev_log = { prefs.dev_log, "table", true },
      closing_tags = { prefs.closing_tags, "table", true },
    })
  end
end

---Create a proportional split using a percentage specified as a float
---@param percentage number
---@param fallback number
---@return string
local function get_split_cmd(percentage, fallback)
  return ("botright %dvnew"):format(math.max(vim.o.columns * percentage, fallback))
end

local function get_default_lookup()
  local exepath = fn.exepath("flutter")
  local is_snap_installation = exepath and exepath:match("snap") or false
  return (path.is_linux and is_snap_installation) and "flutter sdk-path" or nil
end

M.debug_levels = {
  DEBUG = 1,
  WARN = 2,
}
local config = {
  flutter_path = nil,
  flutter_lookup_cmd = get_default_lookup(),
  pre_run_callback = nil,
  root_patterns = { ".git", "pubspec.yaml" },
  fvm = false,
  default_run_args = nil,
  widget_guides = {
    enabled = false,
    debug = false,
  },
  ui = {
    border = "single",
  },
  decorations = {
    statusline = {
      app_version = false,
      device = false,
    },
  },
  debugger = {
    enabled = false,
    exception_breakpoints = nil,
    evaluate_to_string_in_debug_views = true,
    register_configurations = nil,
  },
  closing_tags = {
    highlight = "Comment",
    prefix = "// ",
    priority = 10,
    enabled = true,
  },
  lsp = {
    debug = M.debug_levels.WARN,
    color = {
      enabled = false,
      background = false,
      foreground = false,
      virtual_text = true,
      virtual_text_str = "■",
      background_color = nil,
    },
  },
  outline = setmetatable({
    auto_open = false,
  }, {
    __index = function(_, k) return k == "open_cmd" and get_split_cmd(0.3, 40) or nil end,
  }),
  dev_log = setmetatable({
    filter = nil,
    enabled = true,
    notify_errors = false,
    focus_on_open = true,
  }, {
    __index = function(_, k) return k == "open_cmd" and get_split_cmd(0.4, 50) or nil end,
  }),
  dev_tools = {
    autostart = false,
    auto_open_browser = false,
  },
}

local deprecations = {
  flutter_outline = {
    fallback = "widget_guides",
    message = "please use 'widget_guides' instead",
  },
}

local function handle_deprecation(key, value, conf)
  local deprecation = deprecations[key]
  if not deprecation then return end
  vim.defer_fn(
    function() ui.notify(fmt("%s is deprecated: %s", key, deprecation.message), ui.WARN) end,
    1000
  )
  if deprecation.fallback then conf[deprecation.fallback] = value end
end

---@param project flutter.ProjectConfig | flutter.ProjectConfig[]
function M.setup_project(project)
  if not utils.islist(project) then project = { project } end
  project_config = project
end

function M.set(user_config)
  if not user_config or type(user_config) ~= "table" then return config end
  validate_prefs(user_config)
  for key, value in pairs(user_config) do
    handle_deprecation(key, value, user_config)
  end
  config = vim.tbl_deep_extend("force", config, user_config)
  return config
end

---@module "flutter-tools.config"
return setmetatable(M, {
  __index = function(_, k)
    if k == "project" then return project_config end
    return config[k]
  end,
})
