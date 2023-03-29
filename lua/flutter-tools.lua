local M = {}

local lazy = require("flutter-tools.lazy")

local commands = lazy.require("flutter-tools.commands") ---@module "flutter-tools.commands"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module "flutter-tools.dev_tools"
local dap = lazy.require("flutter-tools.dap") ---@module "flutter-tools.dap"
local decorations = lazy.require("flutter-tools.decorations") ---@module "flutter-tools.decorations"
local guides = lazy.require("flutter-tools.guides") ---@module "flutter-tools.guides"
local log = lazy.require("flutter-tools.log") ---@module "flutter-tools.log"
local lsp = lazy.require("flutter-tools.lsp") ---@module "flutter-tools.lsp"

local api = vim.api

local function setup_commands()
  local cmd = api.nvim_create_user_command
  -- Commands
  cmd("FlutterRun", function(data) commands.run_command(data.args) end, { nargs = "*" })
  cmd("FlutterLspRestart", function() require("flutter-tools.lsp").restart() end, {})
  cmd("FlutterDetach", function() commands.detach() end, {})
  cmd("FlutterReload", function() commands.reload() end, {})
  cmd("FlutterRestart", function() commands.restart() end, {})
  cmd("FlutterQuit", function() commands.quit() end, {})
  cmd("FlutterVisualDebug", function() commands.visual_debug() end, {})
  -- Lists
  cmd("FlutterDevices", function() require("flutter-tools.devices").list_devices() end, {})
  cmd("FlutterEmulators", function() require("flutter-tools.devices").list_emulators() end, {})
  --- Outline
  cmd("FlutterOutlineOpen", function() require("flutter-tools.outline").open() end, {})
  cmd("FlutterOutlineToggle", function() require("flutter-tools.outline").toggle() end, {})
  --- Dev tools
  cmd("FlutterDevTools", function() require("flutter-tools.dev_tools").start() end, {})
  cmd("FlutterDevToolsActivate", function() require("flutter-tools.dev_tools").activate() end, {})
  cmd("FlutterCopyProfilerUrl", function() commands.copy_profiler_url() end, {})
  cmd("FlutterOpenDevTools", function() commands.open_dev_tools() end, {})
  cmd("FlutterPubGet", function() commands.pub_get() end, {})
  cmd(
    "FlutterPubUpgrade",
    function(data) commands.pub_upgrade_command(data.args) end,
    { nargs = "*" }
  )
  --- Log
  cmd("FlutterLogClear", function() require("flutter-tools.log").clear() end, {})
  --- LSP
  cmd("FlutterSuper", function() require("flutter-tools.lsp").dart_lsp_super() end, {})
  cmd("FlutterReanalyze", function() require("flutter-tools.lsp").dart_reanalyze() end, {})
end

---Initialise various plugin modules
local function start()
  setup_commands()
  if config.debugger.enabled then dap.setup(config) end
  if config.widget_guides.enabled then guides.setup() end
  if config.decorations then decorations.apply(config.decorations) end
end

local AUGROUP = api.nvim_create_augroup("FlutterToolsGroup", { clear = true })
---Create autocommands for the plugin
local function setup_autocommands()
  local autocmd = api.nvim_create_autocmd

  -- delay plugin setup till we enter a dart file
  autocmd({ "BufEnter" }, {
    group = AUGROUP,
    pattern = { "*.dart", "pubspec.yaml" },
    once = true,
    callback = start,
  })

  if config.lsp.color.enabled then
    autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
      group = AUGROUP,
      pattern = { "*.dart" },
      callback = function() lsp.document_color() end,
    })
    -- NOTE: we piggyback of this event to check for when the server is first initialized
    autocmd({ "User" }, {
      group = AUGROUP,
      pattern = "FlutterToolsLspAnalysisComplete",
      once = true,
      callback = function() lsp.document_color() end,
    })
  end

  autocmd({ "BufWritePost" }, {
    group = AUGROUP,
    pattern = { "*.dart" },
    callback = function() commands.reload(true) end,
  })
  autocmd({ "BufWritePost" }, {
    group = AUGROUP,
    pattern = { "*/pubspec.yaml" },
    callback = function() commands.pub_get() end,
  })
  autocmd({ "BufEnter" }, {
    group = AUGROUP,
    pattern = { log.filename },
    callback = function() log.__resurrect() end,
  })
  autocmd({ "VimLeavePre" }, {
    group = AUGROUP,
    pattern = { "*" },
    callback = function() dev_tools.stop() end,
  })
end

---Entry point for this plugin
---@param user_config table
function M.setup(user_config)
  config.set(user_config)
  setup_autocommands()
end

return M
