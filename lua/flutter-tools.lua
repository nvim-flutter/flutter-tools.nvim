local utils = require("flutter-tools.utils")

local M = {}

local function setup_commands()
  -- Commands
  utils.command("FlutterRun", [[lua require('flutter-tools.commands').run()]])
  utils.command("FlutterReload", [[lua require('flutter-tools.commands').reload()]])
  utils.command("FlutterRestart", [[lua require('flutter-tools.commands').restart()]])
  utils.command("FlutterQuit", [[lua require('flutter-tools.commands').quit()]])
  utils.command("FlutterVisualDebug", [[lua require('flutter-tools.commands').visual_debug()]])
  -- Lists
  utils.command("FlutterDevices", [[lua require('flutter-tools.devices').list_devices()]])
  utils.command("FlutterEmulators", [[lua require('flutter-tools.devices').list_emulators()]])
  --- Outline
  utils.command("FlutterOutline", [[lua require('flutter-tools.outline').open()]])
  --- Dev tools
  utils.command("FlutterDevTools", [[lua require('flutter-tools.dev_tools').start()]])
  utils.command("FlutterCopyProfilerUrl", [[lua require('flutter-tools.commands').copy_profiler_url()]])
  --- Log
  utils.command("FlutterLogClear", [[lua require('flutter-tools.log').clear()]])
end

local function setup_autocommands()
  require("flutter-tools.utils").augroup("FlutterToolsHotReload", {
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
end

---Entry point for this plugin
---@param user_config table
---@return nil
function M.setup(user_config)
  local success = pcall(require, "plenary")
  if not success then
    return utils.echomsg("plenary.nvim is a required dependency of this plugin, please ensure it is installed")
  end

  local conf = require("flutter-tools.config").set(user_config)

  require("flutter-tools.lsp").setup()

  if conf.debugger.enabled then
    require("flutter-tools.dap").setup(conf)
  end

  if conf.widget_guides.enabled then
    require("flutter-tools.guides").setup(conf)
  end

  setup_commands()
  setup_autocommands()
end

return M
