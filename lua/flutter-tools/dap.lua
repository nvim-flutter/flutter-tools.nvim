local ui = require("flutter-tools.ui")

local success, dap = pcall(require, "dap")
if not success then
  ui.notify(string.format("nvim-dap is not installed!\n%s", dap), ui.ERROR)
  return
end

local M = {}

function M.select_config(paths, callback)
  local launch_configurations = {}
  local launch_configuration_count = 0
  require("flutter-tools.config").debugger.register_configurations(paths)
  local all_configurations = dap.configurations.dart
  for _, c in ipairs(all_configurations) do
    if c.request == "launch" then
      table.insert(launch_configurations, c)
      launch_configuration_count = launch_configuration_count + 1
    end
  end
  if launch_configuration_count == 0 then
    ui.notify("No launch configuration for DAP found", ui.ERROR)
    return
  elseif launch_configuration_count == 1 then
    callback(launch_configurations[1])
  else
    local launch_options = vim.tbl_map(function(item)
      return {
        text = item.name,
        type = ui.entry_type.DEBUG_CONFIG,
        data = item,
      }
    end, launch_configurations)
    ui.select({
      title = "Select launch configuration",
      lines = launch_options,
      on_select = callback,
    })
  end
end

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
