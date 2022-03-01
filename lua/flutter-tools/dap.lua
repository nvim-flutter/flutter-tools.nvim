local ui = require("flutter-tools.ui")

local success, dap = pcall(require, "dap")
if not success then
  ui.notify({ "nvim-dap is not installed!", dap }, { level = ui.ERROR })
  return
end

local M = {}

function M.setup(config)
  require("flutter-tools.executable").get(function(paths)
    dap.adapters.dart = {
      type = "executable",
      command = "flutter",
      args = { "debug-adapter" },
      options = {
        initialize_timeout_sec = 6,
      },
    }
    config.debugger.register_configurations(paths)
  end)
end

return M
