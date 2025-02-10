local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local executable = lazy.require("flutter-tools.executable") ---@module "flutter-tools.executable"
local Job = require("plenary.job")

local M = {}
local fn = vim.fn

---@type Job?
local job = nil

---@type number?
local devtools_pid = nil

---@type string?
local devtools_url = nil

---@type string?
local profiler_url = nil

--- Url containing the app url and the devtools server url
---@type string?
local devtools_profiler_url = nil

local activate_cmd = { "pub", "global", "activate", "devtools" }

---Android when flutter run starts a new devtools process
---OLD: Flutter DevTools, a Flutter debugger and profiler,
---on sdk gphone x86 arm is available at:
---http://127.0.0.1:9102?uri=http%3A%2F%2F127.0.0.1%3A46051%2FNvCev-HjyX4%3D%2F
---NEW: The Flutter DevTools debugger and profiler on sdk gphone x86 arm is available at:
--- http://127.0.0.1:9100?uri=http%3A%2F%2F127.0.0.1%3A35479%2FgQ0BNyM2xB8%3D%2F
---@param data string
---@return unknown
local function try_get_tools_flutter(data) return data:match("(https?://127%.0%.0%.1:%d+%?uri=.+)$") end

--- Debug service listening on ws://127.0.0.1:44293/heXbxLM_lhM=/ws
--- @param data string
--- @return string?
local function try_get_profiler_url_chrome(data)
  return data:match("(ws%:%/%/127%.0%.0%.1%:%d+/.+/ws)$")
end

---@param url string
local function open_dev_tools(url)
  local open_command = utils.open_command()
  if not open_command then
    return ui.notify(
      "Sorry your Operating System is not supported, please raise an issue",
      ui.ERROR
    )
  end

  Job:new({
    command = open_command,
    args = { url },
    detached = true,
  }):start()
end

local function start_browser()
  local auto_open_browser = config.dev_tools.auto_open_browser
  if not auto_open_browser then return end
  local url = M.get_profiler_url()
  if not url then return end
  open_dev_tools(url)
end

function M.open_dev_tools()
  local url = M.get_profiler_url()
  if url then
    open_dev_tools(url)
  else
    ui.notify("No active devtools server found")
  end
end

---@param data string?
function M.handle_log(data)
  if not data then return end

  if devtools_profiler_url or (profiler_url and devtools_url) then return end

  devtools_profiler_url = try_get_tools_flutter(data)

  if devtools_profiler_url then
    M.handle_devtools_available()
    return
  end

  if profiler_url then return end

  profiler_url = try_get_profiler_url_chrome(data)

  if profiler_url then M.register_profiler_url(profiler_url) end
end

function M.register_profiler_url(url)
  if url then
    profiler_url = url
    local autostart = config.dev_tools.autostart
    if autostart then
      M.start()
      M.handle_devtools_available()
    end
  end
end

function M.handle_devtools_available()
  start_browser()
  ui.notify("Detected devtools url, execute FlutterCopyProfilerUrl to copy it")
end

--[[ {
    event = "server.started",
    method = "server.started",
    params = {
        host = "127.0.0.1",
        pid = 3407971,
        port = 9100,
        protocolVersion = "1.1.0"
    }
}]]
---Open dev tools
---@param _ number
---@param data string
---@param _ Job
local function handle_start(_, data, _)
  if #data <= 0 then return end

  local json = fn.json_decode(data)
  if not json or not json.params then return end

  devtools_pid = json.params.pid
  if not json.params.host or not json.params.port then return end

  devtools_url = string.format("http://%s:%s", json.params.host, json.params.port)
  start_browser()
  ui.notify(string.format("Serving DevTools at %s", devtools_url), ui.INFO, { timeout = 10000 })
end

---Handler errors whilst opening dev tools
---@param _ number
---@param data string
---@param _ Job
local function handle_error(_, data, _)
  if not data:match("No active package devtools") then
    ui.notify(utils.join({ "Sorry! devtools couldn't be opened", vim.inspect(data) }), ui.ERROR)
    return
  end
  ui.notify({
    "Flutter pub global devtools has not been activated.",
    "Run :FlutterDevToolsActivate to activate it.",
  })
end

--- @return boolean
local function can_start() return not job and not devtools_url and not devtools_profiler_url end

function M.start()
  if can_start() then
    ui.notify("Starting dev tools...")
    executable.dart(function(cmd)
      job = Job:new({
        command = cmd,
        args = {
          "devtools",
          "--machine",
        },
        on_stdout = vim.schedule_wrap(handle_start),
        on_stderr = vim.schedule_wrap(handle_error),
        on_exit = vim.schedule_wrap(function()
          job = nil
          ui.notify("Dev tools closed")
        end),
      })
      if not job then return end

      job:start()
    end)
  else
    ui.notify("DevTools are already running!")
  end
end

function M.activate()
  ui.notify({ "Activating dev tools..." })
  executable.flutter(function(cmd)
    job = Job:new({
      command = cmd,
      args = activate_cmd,
      on_stderr = vim.schedule_wrap(
        function(_, data, _) ui.notify({ "Unable to activate devtools!", vim.inspect(data) }) end
      ),
      on_exit = vim.schedule_wrap(function(_, return_value)
        job = nil
        if return_value == 0 then ui.notify({ "Dev tools activated" }) end
      end),
    })
    if not job then return end

    job:start()
  end)
end

function M.stop()
  if devtools_pid then
    local uv = vim.loop
    uv.kill(devtools_pid, uv.constants.SIGTERM)
    devtools_pid = nil
    devtools_url = nil
  end
end

---@return string? devtools_url @see devtools_url
function M.get_url() return devtools_url end

---@return boolean
function M.is_running() return devtools_profiler_url ~= nil or devtools_url ~= nil end

---@return string? devtools_profiler_url the url including the devtools url and the app url. Follows the format `devtools_url/?uri=app_url`
---@return boolean? server_running true if there is a `devtools_url` available but couldn't build the url
function M.get_profiler_url()
  if devtools_profiler_url then
    return devtools_profiler_url
  elseif devtools_url and profiler_url then
    return string.format("%s/?uri=%s", devtools_url, profiler_url)
  else
    return nil, devtools_url ~= nil
  end
end

function M.on_flutter_shutdown()
  profiler_url = nil
  devtools_profiler_url = nil
end

function M.set_devtools_url(url) devtools_url = url end

function M.set_profiler_url(url) profiler_url = url end

return M
