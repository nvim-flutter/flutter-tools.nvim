local Job = require("plenary.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local devices = require("flutter-tools.devices")
local config = require("flutter-tools.config")
local executable = require("flutter-tools.executable")
local dev_log = require("flutter-tools.log")

local api = vim.api

local M = {}

---@type Job
local run_job = nil

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
---@param is_err boolean if this is stdout or stderr
---@param opts table config options for the dev log window
---@return fun(err: string, data: string, job: Job): nil
local function on_run_data(is_err, opts)
  return vim.schedule_wrap(function(_, data, _)
    if is_err then
      ui.notify({ data })
    end
    if not match_error_string(data) then
      dev_log.log(data, opts)
    end
  end)
end

---Handle a finished flutter run command
---@param result string[]
local function on_run_exit(result)
  local matched_error, msg = has_recoverable_error(result)
  if matched_error then
    local lines, win_devices, highlights = devices.extract_device_props(result)
    ui.popup_create({
      title = "Flutter run (" .. msg .. ") ",
      lines = lines,
      highlights = highlights,
      on_create = function(buf, _)
        vim.b.devices = win_devices
        api.nvim_buf_set_keymap(
          buf,
          "n",
          "<CR>",
          ":lua __flutter_tools_select_device()<CR>",
          { silent = true, noremap = true }
        )
      end,
    })
  end
end

local function shutdown()
  if run_job then
    run_job = nil
  end
end

function M.run(device)
  if run_job then
    return utils.echomsg("Flutter is already running!")
  end
  executable.get(function(cmd)
    local args = { "run" }
    if device and device.id then
      vim.list_extend(args, { "-d", device.id })
    end
    ui.notify({ "Starting flutter project..." })
    local conf = config.get("dev_log")
    run_job = Job:new({
      command = cmd,
      args = args,
      on_stdout = on_run_data(false, conf),
      on_stderr = on_run_data(true, conf),
      on_exit = vim.schedule_wrap(function(j, _)
        on_run_exit(j:result())
        shutdown()
      end),
    })

    run_job:start()
  end)
end

---@param cmd string
---@param quiet boolean
---@param on_send function|nil
local function send(cmd, quiet, on_send)
  if run_job then
    run_job:send(cmd)
    if on_send then
      on_send()
    end
  elseif not quiet then
    utils.echomsg([[Sorry! Flutter is not running]])
  end
end

---@param quiet boolean
function M.reload(quiet)
  send("r", quiet)
end

---@param quiet boolean
function M.restart(quiet)
  send("R", quiet, function()
    if not quiet then
      ui.notify({ "Restarting..." }, 1500)
    end
  end)
end

---@param quiet boolean
function M.quit(quiet)
  send("q", quiet, function()
    if not quiet then
      ui.notify({ "Closing flutter application..." }, 1500)
      shutdown()
    end
  end)
end

---@param quiet boolean
function M.visual_debug(quiet)
  send("p", quiet)
end

-----------------------------------------------------------------------------//
-- Pub commands
-----------------------------------------------------------------------------//
---Print result of running pub get
---@param result string[]
local function on_pub_get(result)
  ui.notify(result)
end

---@type Job
local pub_get_job = nil

function M.pub_get()
  if not pub_get_job then
    executable.get(function(cmd)
      pub_get_job = Job:new({ command = cmd, args = { "pub", "get" } })
      pub_get_job:after_success(vim.schedule_wrap(function(j)
        on_pub_get(j:result())
        pub_get_job = nil
      end))
      pub_get_job:after_failure(vim.schedule_wrap(function(j)
        on_pub_get(j:stderr_result())
        pub_get_job = nil
      end))
      pub_get_job:start()
    end)
  end
end

return M
