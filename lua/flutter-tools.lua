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
  cmd("FlutterOpenDevTools", function()
    require("flutter-tools.commands").open_dev_tools()
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
  --- LSP
  cmd("FlutterSuper", function()
    require("flutter-tools.lsp").dart_lsp_super()
  end, {})
  cmd("FlutterReanalyze", function()
    require("flutter-tools.lsp").dart_reanalyze()
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

  if require("flutter-tools.config").get("lsp").color.enabled then
    autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
      group = AUGROUP,
      pattern = { "*.dart" },
      callback = function()
        require("flutter-tools.lsp").document_color()
      end,
    })
    -- NOTE: we piggyback of this event to check for when the server is first initialized
    autocmd({ "User" }, {
      group = AUGROUP,
      pattern = "FlutterToolsLspAnalysisComplete",
      once = true,
      callback = function()
        require("flutter-tools.lsp").document_color()
      end,
    })
  end

  autocmd({ "BufWritePost" }, {
    group = AUGROUP,
    pattern = { "*.dart" },
    callback = function()
      require("flutter-tools.commands").reload(true)
    end,
  })
  autocmd({ "BufWritePost" }, {
    group = AUGROUP,
    pattern = { "*/pubspec.yaml" },
    callback = function()
      require("flutter-tools.commands").pub_get()
    end,
  })
  autocmd({ "BufEnter" }, {
    group = AUGROUP,
    pattern = { require("flutter-tools.log").filename },
    callback = function()
      require("flutter-tools.log").__resurrect()
    end,
  })
  autocmd({ "VimLeavePre" }, {
    group = AUGROUP,
    pattern = { "*" },
    callback = function()
      require("flutter-tools.dev_tools").stop()
    end,
  })
end

---Entry point for this plugin
---@param user_config table
function M.setup(user_config)
  require("flutter-tools.config").set(user_config)
  setup_autocommands()
end

return M
