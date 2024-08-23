local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module "flutter-tools.dev_tools"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local vm_service_extensions = lazy.require("flutter-tools.runners.vm_service_extensions") ---@module "flutter-tools.runners.vm_service_extensions"
local _, dap = pcall(require, "dap")

local fmt = string.format

---@type flutter.Runner
local DebuggerRunner = {}

local plugin_identifier = "flutter-tools"

local command_requests = {
  restart = "hotRestart",
  reload = "hotReload",
  quit = "terminate",
  inspect = "widgetInspector",
  construction_lines = "constructionLines",
}

function DebuggerRunner:is_running() return dap.session() ~= nil end

function DebuggerRunner:run(paths, args, cwd, on_run_data, on_run_exit)
  local started = false
  local before_start_logs = {}
  vm_service_extensions.reset()
  dap.listeners.after["event_output"][plugin_identifier] = function(_, body)
    if body and body.output then
      for line in body.output:gmatch("[^\r\n]+") do
        if not started then table.insert(before_start_logs, line) end
        on_run_data(body.category == "sterr", line)
      end
    end
  end

  local handle_termination = function()
    if next(before_start_logs) ~= nil then on_run_exit(before_start_logs, args) end
  end

  dap.listeners.before["event_exited"][plugin_identifier] = function(_, _) handle_termination() end
  dap.listeners.before["event_terminated"][plugin_identifier] = function(_, _) handle_termination() end

  dap.listeners.before["event_app.started"][plugin_identifier] = function(_, _)
    started = true
    before_start_logs = {}
    utils.emit_event(utils.events.APP_STARTED)
  end

  dap.listeners.before["event_dart.debuggerUris"][plugin_identifier] = function(_, body)
    if body and body.vmServiceUri then dev_tools.register_profiler_url(body.vmServiceUri) end
  end

  dap.listeners.before["event_dart.serviceExtensionAdded"][plugin_identifier] = function(_, body)
    if body and body.extensionRPC and body.isolateId then
      vm_service_extensions.set_isolate_id(body.extensionRPC, body.isolateId)
    end
  end

  dap.listeners.before["event_flutter.serviceExtensionStateChanged"][plugin_identifier] = function(
    _,
    body
  )
    if body and body.extension and body.value then
      vm_service_extensions.set_service_extensions_state(body.extension, body.value)
    end
  end

  local launch_configurations = {}
  local launch_configuration_count = 0
  config.debugger.register_configurations(paths)
  local all_configurations = require("dap").configurations.dart
  for _, c in ipairs(all_configurations) do
    if c.request == "launch" then
      table.insert(launch_configurations, c)
      launch_configuration_count = launch_configuration_count + 1
    end
  end

  if launch_configuration_count == 0 then
    ui.notify("No launch configuration for DAP found", ui.ERROR)
    return
  else
    require("dap.ui").pick_if_many(
      launch_configurations,
      "Select launch configuration",
      function(item)
        return fmt("%s : %s | %s", item.name, item.program or item.cwd, vim.inspect(item.args))
      end,
      function(launch_config)
        if not launch_config then return end
        launch_config = vim.deepcopy(launch_config)
        launch_config.cwd = launch_config.cwd or cwd
        launch_config.args = vim.list_extend(launch_config.args or {}, args or {})
        launch_config.dartSdkPath = paths.dart_sdk
        launch_config.flutterSdkPath = paths.flutter_sdk
        if config.debugger.evaluate_to_string_in_debug_views then
          launch_config.evaluateToStringInDebugViews = true
        end
        dap.run(launch_config)
      end
    )
  end
end

function DebuggerRunner:send(cmd, quiet)
  local request = command_requests[cmd]
  if request ~= nil then
    dap.session():request(request)
    return
  end
  local service_activation_params = vm_service_extensions.get_request_params(cmd)
  if service_activation_params then
    dap.session():request("callService", service_activation_params)
    return
  end
  if not quiet then
    ui.notify("Command " .. cmd .. " is not yet implemented for DAP runner", ui.ERROR)
  end
end

function DebuggerRunner:cleanup()
  if dap.session() then dap.terminate() end
end

return DebuggerRunner
