local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"

local success, dap = pcall(require, "dap")
if not success then
  ui.notify(string.format("nvim-dap is not installed!\n%s", dap), ui.ERROR)
  return
end

local M = {}

function M.setup(config)
  local opts = config.debugger
  require("flutter-tools.executable").get(function(_)
    if opts.exception_breakpoints and type(opts.exception_breakpoints) == "table" then
      dap.defaults.dart.exception_breakpoints = opts.exception_breakpoints
    end
  end)
end

return M
