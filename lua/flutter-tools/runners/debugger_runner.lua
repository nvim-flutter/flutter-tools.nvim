local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module "flutter-tools.dev_tools"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"
local vm_service_extensions = lazy.require("flutter-tools.runners.vm_service_extensions") ---@module "flutter-tools.runners.vm_service_extensions"
local vm_service = lazy.require("flutter-tools.vm_service") ---@module "flutter-tools.vm_service"
local success, dap = pcall(require, "dap")
if not success then
  ui.notify(string.format("nvim-dap is not installed!\n%s", dap), ui.ERROR)
  return
end

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
---@param cwd string?
local function register_default_configurations(paths, is_flutter_project, project_config, cwd)
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
        cwd = cwd,
      },
      {
        type = "dart",
        request = "attach",
        name = "Connect flutter",
        dartSdkPath = paths.dart_sdk,
        flutterSdkPath = paths.flutter_sdk,
        program = program,
        cwd = cwd,
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
        cwd = cwd,
      },
    }
  end
end

local function get_current_value(cmd)
  local service_activation_params = vm_service_extensions.get_request_params(cmd)
  if not service_activation_params or not service_activation_params.params.isolateId then return end

  service_activation_params.params = {
    isolateId = service_activation_params.params.isolateId,
  }
  dap.session():request("callService", service_activation_params, function(err, result)
    if err then return end
    vm_service_extensions.set_service_extensions_state(result.method, result.value)
  end)
end

local function handle_inspect_event(isolate_id)
  local session = dap.session()
  if not session or not isolate_id then return end

  local inspector_group = "flutter-tools-inspector"

  local params = {
    method = "ext.flutter.inspector.getSelectedSummaryWidget",
    params = {
      previousSelectionId = vim.NIL,
      objectGroup = inspector_group,
      isolateId = isolate_id,
    },
  }

  session:request("callService", params, function(err, result)
    if err or not result then return end

    local widget_data = result.result or result
    local location = widget_data.creationLocation
    if not location and widget_data.children and widget_data.children[1] then
      location = widget_data.children[1].creationLocation
    end

    if location and location.file and location.line then
      local file = location.file:gsub("^file://", "")
      if vim.uv.os_uname().sysname == "Windows_NT" then
        -- On Windows, the file URI may start with an extra slash
        file = file:gsub("^/", "")
      end
      vim.schedule(function()
        vim.cmd("edit " .. vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { location.line, (location.column or 1) - 1 })
      end)
    end

    session:request("callService", {
      method = "ext.flutter.inspector.disposeGroup",
      params = { objectGroup = inspector_group, isolateId = isolate_id },
    }, function() end)
  end)
end

local listened_events = {
  { "after", "event_output" },
  { "before", "event_exited" },
  { "before", "event_terminated" },
  { "before", "event_app.started" },
  { "before", "event_dart.debuggerUris" },
  { "before", "event_dart.serviceExtensionAdded" },
  { "before", "event_flutter.serviceExtensionStateChanged" },
}

local function unregister_dap_listeners()
  for _, event in ipairs(listened_events) do
    dap.listeners[event[1]][event[2]][plugin_identifier] = nil
  end
end

---@param on_run_data fun(is_err: boolean, line: string)
---@param on_run_exit fun(before_start_logs: string[])
local function register_dap_listeners(on_run_data, on_run_exit)
  vm_service_extensions.reset()
  local started = false
  local before_start_logs = {}
  dap.listeners.after["event_output"][plugin_identifier] = function(_, body)
    if not body or not body.output then return end
    for line in body.output:gmatch("[^\r\n]+") do
      if not started then table.insert(before_start_logs, line) end
      on_run_data(body.category == "stderr", line)
    end
  end

  local handle_termination = function()
    if next(before_start_logs) ~= nil then on_run_exit(before_start_logs) end
    if vm_service.is_connected() then vm_service.disconnect() end
  end

  dap.listeners.before["event_exited"][plugin_identifier] = function(_, _) handle_termination() end
  dap.listeners.before["event_terminated"][plugin_identifier] = function(_, _) handle_termination() end

  dap.listeners.before["event_app.started"][plugin_identifier] = function(_, _)
    started = true
    before_start_logs = {}
    utils.emit_event(utils.events.APP_STARTED)
  end

  dap.listeners.before["event_dart.debuggerUris"][plugin_identifier] = function(_, body)
    if body and body.vmServiceUri then
      dev_tools.register_profiler_url(body.vmServiceUri)

      vm_service.connect(body.vmServiceUri, function()
        vm_service.stream_listen("Debug", function(event)
          if event and event.kind == "Inspect" and event.isolate and event.isolate.id then
            handle_inspect_event(event.isolate.id)
          end
        end)
      end)
    end
  end

  dap.listeners.before["event_dart.serviceExtensionAdded"][plugin_identifier] = function(_, body)
    if body and body.extensionRPC and body.isolateId then
      vm_service_extensions.set_isolate_id(body.extensionRPC, body.isolateId)
      if body.extensionRPC == "ext.flutter.brightnessOverride" then
        get_current_value("brightness")
      elseif body.extensionRPC == "ext.flutter.platformOverride" then
        get_current_value("change_target_platform")
      end
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

---@class flutter.DebuggerListeners
---@field on_run_data fun(is_err: boolean, line: string)
---@field on_run_exit fun(before_start_logs: string[])

---Listeners for the session the next `dap.run` call starts
---@type flutter.DebuggerListeners?
local pending_listeners = nil

---@type fun(): flutter.DebuggerListeners?
local get_untracked_session_listeners = function() end

local tracked_session_id = nil

---@param launch_config dap.Configuration
---@param listeners flutter.DebuggerListeners
local function start_session(launch_config, listeners)
  pending_listeners = listeners
  dap.run(launch_config)
end

dap.listeners.on_session[plugin_identifier] = function(_, session)
  if not session or session.config.type ~= "dart" or session.id == tracked_session_id then
    return
  end
  tracked_session_id = session.id
  local listeners = pending_listeners or get_untracked_session_listeners()
  pending_listeners = nil
  if listeners then
    register_dap_listeners(listeners.on_run_data, listeners.on_run_exit)
  else
    unregister_dap_listeners()
  end
end

---Set the listeners for dart sessions started outside flutter-tools, e.g. via `dap.continue()`
---@param get_listeners fun(): flutter.DebuggerListeners?
function DebuggerRunner.on_untracked_session(get_listeners)
  get_untracked_session_listeners = get_listeners
end

---Register the adapter and launch configurations up front so `dap.continue()` works before any
---flutter-tools command has run. Adapters and configurations the user defined are left in place.
---@param paths table<string, string>
---@param is_flutter_project boolean
---@param project_config flutter.ProjectConfig?
---@param cwd string?
function DebuggerRunner.register_defaults(paths, is_flutter_project, project_config, cwd)
  if not dap.adapters.dart then register_debug_adapter(paths, is_flutter_project) end
  if not dap.configurations.dart then
    register_default_configurations(paths, is_flutter_project, project_config, cwd)
  end
  if config.debugger.register_configurations then config.debugger.register_configurations(paths) end
end

function DebuggerRunner:run(
  opts,
  paths,
  args,
  cwd,
  on_run_data,
  on_run_exit,
  is_flutter_project,
  project_config,
  last_launch_config
)
  ---@type dap.Configuration
  local selected_launch_config = nil

  ---@type flutter.DebuggerListeners
  local listeners = {
    on_run_data = on_run_data,
    on_run_exit = function(before_start_logs)
      on_run_exit(before_start_logs, args, opts, project_config, selected_launch_config)
    end,
  }

  register_debug_adapter(paths, is_flutter_project)
  local launch_configurations = {}
  local launch_configuration_count = 0
  if last_launch_config then
    start_session(last_launch_config, listeners)
    return
  else
    register_default_configurations(paths, is_flutter_project, project_config, cwd)
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
        start_session(launch_config, listeners)
      end
    )
  end
end

function DebuggerRunner:attach(paths, args, cwd, on_run_data, on_run_exit)
  ---@type flutter.DebuggerListeners
  local listeners = {
    on_run_data = on_run_data,
    on_run_exit = function(before_start_logs) on_run_exit(before_start_logs, args) end,
  }

  register_debug_adapter(paths, true)
  local launch_configurations = {}
  local launch_configuration_count = 0
  register_default_configurations(paths, true, nil, cwd)
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
        start_session(launch_config, listeners)
      end
    )
  end
end

function DebuggerRunner:send(cmd, quiet, on_response)
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
    dap.session():request("callService", service_activation_params, function(err, response)
      if err and not quiet then
        ui.notify("Error calling service " .. cmd .. ": " .. err, ui.ERROR)
      end
      if response and on_response then on_response(response) end
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
