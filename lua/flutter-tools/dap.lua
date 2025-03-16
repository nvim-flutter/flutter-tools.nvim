local M = {}

function M.setup(config)
  local success, dap = pcall(require, "dap")
  if success then
    local opts = config.debugger
    require("flutter-tools.executable").get(function(_)
      if opts.exception_breakpoints and type(opts.exception_breakpoints) == "table" then
        dap.defaults.dart.exception_breakpoints = opts.exception_breakpoints
      end
    end)
  end
end

return M
