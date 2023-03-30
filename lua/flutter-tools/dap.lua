local ui = require("flutter-tools.ui")

local success, dap = pcall(require, "dap")
if not success then
  ui.notify(string.format("nvim-dap is not installed!\n%s", dap), ui.ERROR)
  return
end

local M = {}

function M.setup(config)
  local opts = config.debugger
  require("flutter-tools.executable").get(function(paths)
    dap.adapters.dart = {
      type = "executable",
      command = paths.flutter_bin,
      args = { "debug-adapter" },
    }
    opts.register_configurations(paths)
    if opts.exception_breakpoints and type(opts.exception_breakpoints) == "table" then
      dap.defaults.dart.exception_breakpoints = opts.exception_breakpoints
    end
  end)
end

return M
