local ui = require("flutter-tools.ui")
local dev_tools = require("flutter-tools.dev_tools")
local config = require("flutter-tools.config")
local _, dap = pcall(require, "dap")

local fmt = string.format

---@type FlutterRunner
local DAPRunner = {}

local service_extensions_isolateid = {}
local service_extensions_state = {}

local plugin_identifier = "flutter-tools"

local command_requests = {
  restart = "hotRestart",
  reload = "hotReload",
  quit = "terminate",
  inspect = "widgetInspector",
  construction_lines = "constructionLines",
}

local service_activation_requests = {
  visual_debug = "ext.flutter.debugPaint",
}

function DAPRunner:is_running()
  return dap.session() ~= nil
end

function DAPRunner:run(paths, args, cwd, on_run_data, on_run_exit)
  local started = false
  local before_start_logs = {}
  service_extensions_isolateid = {}
  dap.listeners.after["event_output"][plugin_identifier] = function(_, body)
    if body and body.output then
      for line in body.output:gmatch("[^\r\n]+") do
        if not started then
          table.insert(before_start_logs, line)
        end
        on_run_data(body.category == "sterr", line)
      end
    end
  end

  local handle_termination = function()
    if next(before_start_logs) ~= nil then
      on_run_exit(before_start_logs, args)
    end
  end

  dap.listeners.before["event_exited"][plugin_identifier] = function(_, _)
    handle_termination()
  end
  dap.listeners.before["event_terminated"][plugin_identifier] = function(_, _)
    handle_termination()
  end

  dap.listeners.before["event_app.started"][plugin_identifier] = function(_, _)
    started = true
    before_start_logs = {}
    vim.cmd("doautocmd User FlutterToolsAppStarted")
  end

  dap.listeners.before["event_dart.debuggerUris"][plugin_identifier] = function(_, body)
    if body and body.observatoryUri then
      dev_tools.register_profiler_url(body.observatoryUri)
    end
  end

  dap.listeners.before["event_dart.serviceExtensionAdded"][plugin_identifier] = function(_, body)
    if body and body.extensionRPC and body.isolateId then
      service_extensions_isolateid[body.extensionRPC] = body.isolateId
    end
  end

  dap.listeners.before["event_flutter.serviceExtensionStateChanged"][plugin_identifier] =
    function(_, body)
      if body and body.extension and body.value then
        service_extensions_state[body.extension] = body.value
      end
    end

  local launch_configurations = {}
  local launch_configuration_count = 0
  config.get().debugger.register_configurations(paths)
  local all_configurations = require("dap").configurations.dart
  for _, c in ipairs(all_configurations) do
    if c.request == "launch" then
      table.insert(launch_configurations, c)
      launch_configuration_count = launch_configuration_count + 1
    end
  end

  local launch_config
  if launch_configuration_count == 0 then
    ui.notify({ "No launch configuration for DAP found" }, { level = ui.ERROR })
    return
  elseif launch_configuration_count == 1 then
    launch_config = launch_configurations[1]
  else
    launch_config = require("dap.ui").pick_one_sync(
      launch_configurations,
      "Select launch configuration",
      function(item)
        return fmt("%s : %s", item.name, item.program, vim.inspect(item.args))
      end
    )
  end
  if not launch_config then
    return
  end
  launch_config = vim.deepcopy(launch_config)
  launch_config.cwd = cwd
  launch_config.args = vim.list_extend(launch_config.args or {}, args or {})
  launch_config.dartSdkPath = paths.dart_sdk
  launch_config.flutterSdkPath = paths.flutter_sdk
  dap.run(launch_config)
end

function DAPRunner:send(cmd, quiet)
  local request = command_requests[cmd]
  local service_activation_request = service_activation_requests[cmd]
  if request ~= nil then
    dap.session():request(request)
  elseif service_activation_request then
    local new_value
    if service_extensions_state[service_activation_request] == "true" then
      new_value = "false"
    else
      new_value = "true"
    end
    dap.session():request("callService", {
      method = service_activation_request,
      params = {
        enabled = new_value,
        isolateId = service_extensions_isolateid[service_activation_request],
      },
    })
  elseif not quiet then
    ui.notify(
      { "Command " .. cmd .. " is not yet implemented for DAP runner" },
      { level = ui.ERROR }
    )
  end
end

function DAPRunner:cleanup()
  if dap.session() then
    dap.terminate()
  end
end

return DAPRunner
