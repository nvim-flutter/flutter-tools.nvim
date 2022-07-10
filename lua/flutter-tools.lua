local M = {}

local api = vim.api

local function setup_commands()
  local cmd = api.nvim_create_user_command
  -- Commands
  cmd("FlutterRun", function(data)
    require("flutter-tools.commands").run_command(data.args)
  end, { nargs = "*" })
  cmd("FlutterLspRestart", function()
    require("flutter-tools.lsp").restart()
  end, {})
  cmd("FlutterDetach", function()
    require("flutter-tools.commands").detach()
  end, {})
  cmd("FlutterReload", function()
    require("flutter-tools.commands").reload()
  end, {})
  cmd("FlutterRestart", function()
    require("flutter-tools.commands").restart()
  end, {})
  cmd("FlutterQuit", function()
    require("flutter-tools.commands").quit()
  end, {})
  cmd("FlutterVisualDebug", function()
    require("flutter-tools.commands").visual_debug()
  end, {})
  -- Lists
  cmd("FlutterDevices", function()
    require("flutter-tools.devices").list_devices()
  end, {})
  cmd("FlutterEmulators", function()
    require("flutter-tools.devices").list_emulators()
  end, {})
  --- Outline
  cmd("FlutterOutlineOpen", function()
    require("flutter-tools.outline").open()
  end, {})
  cmd("FlutterOutlineToggle", function()
    require("flutter-tools.outline").toggle()
  end, {})
  --- Dev tools
  cmd("FlutterDevTools", function()
    require("flutter-tools.dev_tools").start()
  end, {})
  cmd("FlutterCopyProfilerUrl", function()
    require("flutter-tools.commands").copy_profiler_url()
  end, {})
  cmd("FlutterPubGet", function()
    require("flutter-tools.commands").pub_get()
  end, {})
  cmd("FlutterPubUpgrade", function(data)
    require("flutter-tools.commands").pub_upgrade_command(data.args)
  end, { nargs = "*" })
  --- Log
  cmd("FlutterLogClear", function()
    require("flutter-tools.log").clear()
  end, {})
end

---Initialise various plugin modules
local function start()
  setup_commands()

  local conf = require("flutter-tools.config").get()
  if conf.debugger.enabled then require("flutter-tools.dap").setup(conf) end
  if conf.widget_guides.enabled then require("flutter-tools.guides").setup() end
  if conf.decorations then require("flutter-tools.decorations").apply(conf.decorations) end
end

---Create autocommands for the plugin
local function setup_autocommands()
  local utils = require("flutter-tools.utils")

  -- delay plugin setup till we enter a dart file
  utils.augroup("FlutterToolsStart", {
    {
      events = { "BufEnter" },
      targets = { "*.dart" },
      modifiers = { "++once" },
      command = start,
    },
  })

  local color_enabled = require("flutter-tools.config").get("lsp").color.enabled
  if color_enabled then
    utils.augroup("FlutterToolsLspColors", {
      {
        events = { "BufEnter", "TextChanged", "InsertLeave" },
        targets = { "*.dart" },
        command = function()
          require("flutter-tools.lsp").document_color()
        end,
      },
      {
        -- NOTE: we piggyback of this event to check for when the server is first initialized
        events = { "User FlutterToolsLspAnalysisComplete" },
        modifiers = { "++once" },
        command = function()
          require("flutter-tools.lsp").document_color()
        end,
      },
    })
  end

  utils.augroup("FlutterToolsHotReload", {
    {
      events = { "BufWritePost" },
      targets = { "*.dart" },
      command = "lua require('flutter-tools.commands').reload(true)",
    },
    {
      events = { "BufWritePost" },
      targets = { "*/pubspec.yaml" },
      command = "lua require('flutter-tools.commands').pub_get()",
    },
    {
      events = { "BufEnter" },
      targets = { require("flutter-tools.log").filename },
      command = "lua require('flutter-tools.log').__resurrect()",
    },
  })

  utils.augroup("FlutterToolsOnClose", {
    {
      events = { "VimLeavePre" },
      targets = { "*" },
      command = "lua require('flutter-tools.dev_tools').stop()",
    },
  })
end

---Entry point for this plugin
---@param user_config table
function M.setup(user_config)
  require("flutter-tools.config").set(user_config)
  setup_autocommands()
end

return M
