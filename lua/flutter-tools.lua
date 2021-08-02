local M = {}

local function setup_commands()
  local utils = require("flutter-tools.utils")
  -- Commands
  utils.command(
    "FlutterRun",
    [[lua require('flutter-tools.commands').run_command(<q-args>)]],
    { nargs = "*" }
  )
  utils.command("FlutterReload", [[lua require('flutter-tools.commands').reload()]])
  utils.command("FlutterRestart", [[lua require('flutter-tools.commands').restart()]])
  utils.command("FlutterQuit", [[lua require('flutter-tools.commands').quit()]])
  utils.command("FlutterVisualDebug", [[lua require('flutter-tools.commands').visual_debug()]])
  -- Lists
  utils.command("FlutterDevices", [[lua require('flutter-tools.devices').list_devices()]])
  utils.command("FlutterEmulators", [[lua require('flutter-tools.devices').list_emulators()]])
  --- Outline
  utils.command("FlutterOutlineOpen", [[lua require('flutter-tools.outline').open()]])
  utils.command("FlutterOutlineToggle", [[lua require('flutter-tools.outline').toggle()]])
  --- Dev tools
  utils.command("FlutterDevTools", [[lua require('flutter-tools.dev_tools').start()]])
  utils.command(
    "FlutterCopyProfilerUrl",
    [[lua require('flutter-tools.commands').copy_profiler_url()]]
  )
  utils.command("FlutterPubGet", [[lua require('flutter-tools.commands').pub_get()]])
  utils.command(
    "FlutterPubUpgrade",
    [[lua require('flutter-tools.commands').pub_upgrade_command(<q-args>)]],
    { nargs = "*" }
  )
  --- Log
  utils.command("FlutterLogClear", [[lua require('flutter-tools.log').clear()]])
end

---Initialise various plugin modules
local function start()
  -- this loads plenary to check if it exists, so defer it till the plugin is starting up
  if not pcall(require, "plenary") then
    return vim.notify(
      "plenary.nvim is a required dependency of this plugin, please ensure it is installed."
        .. " Otherwise this plugin will not work correctly",
      vim.log.levels.ERROR
    )
  end

  setup_commands()

  local conf = require("flutter-tools.config").get()
  if conf.debugger.enabled then
    require("flutter-tools.dap").setup(conf)
  end

  if conf.widget_guides.enabled then
    require("flutter-tools.guides").setup()
  end

  if conf.decorations then
    require("flutter-tools.decorations").apply(conf.decorations)
  end
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

  -- Setup LSP autocommand to attach to dart files
  utils.augroup("FlutterToolsLsp", {
    {
      events = { "FileType" },
      targets = { "dart" },
      command = "lua require('flutter-tools.lsp').attach()",
    },
  })

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
