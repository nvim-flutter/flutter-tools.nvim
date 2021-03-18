local Job = require("flutter-tools.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local devices = require("flutter-tools.devices")
local config = require("flutter-tools.config")
local executable = require("flutter-tools.executable")
local dev_log = require("flutter-tools.log")

local api = vim.api

local M = {}

local state = {
  ---@type Job
  job = nil
}

local function match_error_string(line)
  if not line then
    return false
  end
  -- match the error string if no devices are setup
  if line:match("No supported devices connected") ~= nil then
    -- match the error string returned if multiple devices are matched
    return true, "Choose a device"
  elseif line:match("More than one device connected") ~= nil then
    return true, "Choose a device"
  end
end

---@param lines string[]
---@return boolean, string
local function has_recoverable_error(lines)
  for _, line in pairs(lines) do
    local match, msg = match_error_string(line)
    if match then
      return match, msg
    end
  end
  return false, nil
end

---Handle output from flutter run command
---@param err boolean
---@param opts table config options for the dev log window
---@return fun(job: Job, data: string): nil
local function on_run_data(err, opts)
  return function(_, data)
    if err then
      ui.notify({data})
    end
    if not match_error_string(data) then
      dev_log.log(data, opts)
    end
  end
end

local function on_run_exit(result)
  local matched_error, msg = has_recoverable_error(result)
  if matched_error then
    local lines, win_devices, highlights = devices.extract_device_props(result)
    ui.popup_create(
      "Flutter run (" .. msg .. ") ",
      lines,
      function(buf, _)
        vim.b.devices = win_devices
        ui.add_highlights(buf, highlights)
        api.nvim_buf_set_keymap(
          buf,
          "n",
          "<CR>",
          ":lua __flutter_tools_select_device()<CR>",
          {silent = true, noremap = true}
        )
      end
    )
  end
end

local function shutdown()
  if state.job then
    state.job:close()
    state.job = nil
  end
  devices.close_emulator()
end

function M.run(device)
  local cfg = config.get()
  local cmd = executable.with("run")
  if state.job then
    return utils.echomsg("Flutter is already running!")
  end
  if device and device.id then
    cmd = cmd .. " -d " .. device.id
  end
  ui.notify {"Starting flutter project..."}
  state.job =
    Job:new {
    cmd = cmd,
    on_stdout = on_run_data(false, cfg.dev_log),
    on_stderr = on_run_data(true, cfg.dev_log),
    on_exit = function(_, result)
      on_run_exit(result)
      shutdown()
    end
  }:start()
end

---@param cmd string
---@param quiet boolean
local function send(cmd, quiet)
  if state.job then
    state.job:send(cmd)
  elseif not quiet then
    utils.echomsg [[Sorry! Flutter is not running]]
  end
end

---@param quiet boolean
function M.reload(quiet)
  send("r", quiet)
end

---@param quiet boolean
function M.restart(quiet)
  if not quiet then
    ui.notify({"Restarting..."}, 1500)
  end
  send("R", quiet)
end

---@param quiet boolean
function M.quit(quiet)
  if not quiet then
    ui.notify({"Closing flutter application..."}, 1500)
  end
  send("q", quiet)
end

---@param quiet boolean
function M.visual_debug(quiet)
  send("p", quiet)
end

-----------------------------------------------------------------------------//
-- Pub commands
-----------------------------------------------------------------------------//
local function on_pub_get(_, result)
  ui.notify(result)
end

---@type Job
local pub_get_job = nil

function M.pub_get()
  if not pub_get_job then
    pub_get_job =
      Job:new {
      cmd = executable.with("pub get"),
      on_exit = function(err, result)
        on_pub_get(err, result)
        pub_get_job = nil
      end
    }:sync()
  end
end

return M
