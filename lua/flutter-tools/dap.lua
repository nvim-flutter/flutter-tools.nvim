local ui = require("flutter-tools.ui")

local success, dap = pcall(require, "dap")
if not success then
  ui.notify(string.format("nvim-dap is not installed!\n%s", dap), ui.ERROR)
  return
end

local M = {}

local function has_flutter_dependency_in_pubspec()
  local pubspec = vim.fn.glob("pubspec.yaml")
  if pubspec == "" then return false end
  local pubspec_content = vim.fn.readfile(pubspec)
  local joined_content = table.concat(pubspec_content, "\n")

  local flutter_dependency = string.match(joined_content, "flutter:\n[%s\t]*sdk:[%s\t]*flutter")
  return flutter_dependency ~= nil
end

function M.setup(config)
  local opts = config.debugger
  require("flutter-tools.executable").get(function(paths)
    local is_flutter_project = has_flutter_dependency_in_pubspec()

    if is_flutter_project then
      dap.adapters.dart = {
        type = "executable",
        command = paths.flutter_bin,
        args = { "debug-adapter" },
      }
      opts.register_configurations(paths)
      local repl = require("dap.repl")
      repl.commands = vim.tbl_extend("force", repl.commands, {
        custom_commands = {
          [".hot-reload"] = function() dap.session():request("hotReload") end,
          [".hot-restart"] = function() dap.session():request("hotRestart") end,
        },
      })
    else
      dap.adapters.dart = {
        type = "executable",
        command = paths.dart_bin,
        args = { "debug_adapter" },
      }
      dap.configurations.dart = {
        {
          type = "dart",
          request = "launch",
          name = "Launch Dart",
          dartSdkPath = paths.dart_sdk,
          program = "${workspaceFolder}/bin/main.dart",
          cwd = "${workspaceFolder}",
        },
      }
    end
    if opts.exception_breakpoints and type(opts.exception_breakpoints) == "table" then
      dap.defaults.dart.exception_breakpoints = opts.exception_breakpoints
    end
  end)
end

return M
