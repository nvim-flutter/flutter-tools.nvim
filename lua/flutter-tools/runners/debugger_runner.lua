local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module "flutter-tools.dev_tools"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
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
}

function DebuggerRunner:is_running() return dap.session() ~= nil end

---@param paths table<string, string>
---@param is_flutter_project boolean
local function register_debug_adapter(paths, is_flutter_project)
  if is_flutter_project then
    dap.adapters.dart = {
      type = "executable",
      command = paths.flutter_bin,
      args = { "debug-adapter" },
    }
    if path.is_windows then
      -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#dart
      -- add this if on windows, otherwise server won't open successfully
      dap.adapters.dart.options = {
        detached = false,
      }
    end
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
  end
end

---@param paths table<string, string>
---@param is_flutter_project boolean
---@param project_config flutter.ProjectConfig?
local function register_default_configurations(paths, is_flutter_project, project_config)
  local program
  if is_flutter_project then
    if project_config and project_config.target then
      program = project_config.target
    else
      program = "lib/main.dart"
    end
    require("dap").configurations.dart = {
      {
        type = "dart",
        request = "launch",
        name = "Launch flutter",
        dartSdkPath = paths.dart_sdk,
        flutterSdkPath = paths.flutter_sdk,
        program = program,
      },
      {
        type = "dart",
        request = "attach",
        name = "Connect flutter",
        dartSdkPath = paths.dart_sdk,
        flutterSdkPath = paths.flutter_sdk,
        program = program,
      },
    }
  else
    if project_config and project_config.target then
      program = project_config.target
    else
      local root_dir_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      program = path.join("bin", root_dir_name .. ".dart")
    end
    require("dap").configurations.dart = {
      {
        type = "dart",
        request = "launch",
        name = "Launch dart",
        dartSdkPath = paths.dart_sdk,
        program = program,
      },
    }
  end
end

local function register_dap_listeners(on_run_data, on_run_exit)
  local started = false
  local before_start_logs = {}
  dap.listeners.after["event_output"][plugin_identifier] = function(_, body)
    on_run_data(started, before_start_logs, body)
  end

  local handle_termination = function()
    if next(before_start_logs) ~= nil then on_run_exit(before_start_logs) end
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
end

function DebuggerRunner:run(
  paths,
  args,
  cwd,
  on_run_data,
  on_run_exit,
  is_flutter_project,
  project_config,
  last_launch_config
)
  vm_service_extensions.reset()
  ---@type dap.Configuration
  local selected_launch_config = nil

  register_dap_listeners(
    function(started, before_start_logs, body)
      if body and body.output then
        for line in body.output:gmatch("[^\r\n]+") do
          if not started then table.insert(before_start_logs, line) end
          on_run_data(body.category == "sterr", line)
        end
      end
    end,
    function(before_start_logs)
      on_run_exit(before_start_logs, args, project_config, selected_launch_config)
    end
  )

  register_debug_adapter(paths, is_flutter_project)
  local launch_configurations = {}
  local launch_configuration_count = 0
  if last_launch_config then
    dap.run(last_launch_config)
    return
  else
    register_default_configurations(paths, is_flutter_project, project_config)
    if config.debugger.register_configurations then
      config.debugger.register_configurations(paths)
    end
    local all_configurations = require("dap").configurations.dart
    if not all_configurations then
      ui.notify("No launch configuration for DAP found", ui.ERROR)
      return
    end
    for _, c in ipairs(all_configurations) do
      if c.request == "launch" then
        table.insert(launch_configurations, c)
        launch_configuration_count = launch_configuration_count + 1
      end
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
        if not launch_config.cwd then launch_config.cwd = cwd end
        launch_config.args = vim.list_extend(launch_config.args or {}, args or {})
        launch_config.dartSdkPath = paths.dart_sdk
        launch_config.flutterSdkPath = paths.flutter_sdk
        if config.debugger.evaluate_to_string_in_debug_views then
          launch_config.evaluateToStringInDebugViews = true
        end
        selected_launch_config = launch_config
        dap.run(launch_config)
      end
    )
  end
end

function DebuggerRunner:attach(paths, args, cwd, on_run_data, on_run_exit)
  vm_service_extensions.reset()
  register_dap_listeners(function(started, before_start_logs, body)
    if body and body.output then
      for line in body.output:gmatch("[^\r\n]+") do
        if not started then table.insert(before_start_logs, line) end
        on_run_data(body.category == "sterr", line)
      end
    end
  end, function(before_start_logs) on_run_exit(before_start_logs, args) end)

  register_debug_adapter(paths, true)
  local launch_configurations = {}
  local launch_configuration_count = 0
  register_default_configurations(paths, true)
  if config.debugger.register_configurations then config.debugger.register_configurations(paths) end
  local all_configurations = require("dap").configurations.dart
  if not all_configurations then
    ui.notify("No launch configuration for DAP found", ui.ERROR)
    return
  end
  for _, c in ipairs(all_configurations) do
    if c.request == "attach" then
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
        if not launch_config.cwd then launch_config.cwd = cwd end
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
  if cmd == "open_dev_tools" then
    dev_tools.open_dev_tools()
    return
  end
  local request = command_requests[cmd]
  if request ~= nil then
    dap.session():request(request, nil, function() end)
    return
  end
  local service_activation_params = vm_service_extensions.get_request_params(cmd)
  if service_activation_params then
    dap.session():request("callService", service_activation_params, function(err, _)
      if err and not quiet then
        ui.notify("Error calling service " .. cmd .. ": " .. err, ui.ERROR)
      end
    end)
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
