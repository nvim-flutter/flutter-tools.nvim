local lazy = require("flutter-tools.lazy")
local dev_tools = lazy.require("flutter-tools.dev_tools") ---@module "flutter-tools.dev_tools"

---@class flutter.VmServiceExtensions
---@field set_service_extensions_state fun(extension: string, value: string)
---@field get_request_params fun(cmd: string): table | nil
---@field reset fun()
---@field set_isolate_id fun(extension: string, isolate_id: string)

local state_key_active_dev_tools_server_address = "ext.flutter.activeDevToolsServerAddress"
local state_key_connected_vm_service_uri = "ext.flutter.connectedVmServiceUri"

local service_extensions_state = {}
local service_extensions_isolateid = {}

local service_activation_requests = {
  visual_debug = "ext.flutter.debugPaint",
  performance_overlay = "ext.flutter.showPerformanceOverlay",
  repaint_rainbow = "ext.flutter.repaintRainbow",
  slow_animations = "ext.flutter.timeDilation",
  inspect_widget = "ext.flutter.inspector.show",
  paint_baselines = "ext.flutter.debugPaintBaselinesEnabled",
}

local toggle_extension_state_keys = {
  visual_debug = "enabled",
  performance_overlay = "enabled",
  repaint_rainbow = "enabled",
  slow_animations = "timeDilation",
  inspect_widget = "enabled",
  paint_baselines = "enabled",
}

local function toggle_value(request)
  local value = service_extensions_state[request]
  if request == service_activation_requests.slow_animations then
    if value == "5.0" then
      return "1.0"
    else
      return "5.0"
    end
  end
  return not value
end

---@type flutter.VmServiceExtensions
return {
  set_service_extensions_state = function(extension, value)
    if extension and value then service_extensions_state[extension] = value end
    if extension == state_key_active_dev_tools_server_address then
      dev_tools.set_devtools_url(value)
    elseif extension == state_key_connected_vm_service_uri then
      dev_tools.set_profiler_url(value)
    end
  end,

  get_request_params = function(cmd)
    local service_activation_request = service_activation_requests[cmd]
    if service_activation_request then
      local key = toggle_extension_state_keys[cmd]
      local new_value = toggle_value(service_activation_request)
      return {
        method = service_activation_request,
        params = {
          [key] = new_value,
          isolateId = service_extensions_isolateid[service_activation_request],
        },
      }
    end
  end,
  reset = function()
    service_extensions_state = {}
    service_extensions_isolateid = {}
  end,
  set_isolate_id = function(extension, isolate_id)
    if extension and isolate_id then service_extensions_isolateid[extension] = isolate_id end
  end,
}
