local M = {}

function M.setup(config)
  local success, dap = pcall(require, "dap")
  if success then
    local opts = config.debugger
    require("flutter-tools.commands").track_debug_sessions()
    require("flutter-tools.executable").get(function(paths)
      if opts.exception_breakpoints and type(opts.exception_breakpoints) == "table" then
        dap.defaults.dart.exception_breakpoints = opts.exception_breakpoints
      end
      local config_utils = require("flutter-tools.utils.config_utils")
      local projects = config.project
      local project_config = #projects == 1 and projects[1] or nil
      local cwd = config_utils.get_cwd(project_config) or vim.fn.getcwd()
      require("flutter-tools.runners.debugger_runner").register_defaults(
        paths,
        config_utils.has_flutter_dependency_in_pubspec(cwd),
        project_config,
        cwd
      )
    end)
  end
end

return M
