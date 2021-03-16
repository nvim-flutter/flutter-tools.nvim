local Job = require("flutter-tools.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local devices = require("flutter-tools.devices")
local dev_log = require("flutter-tools.dev_log")
local config = require("flutter-tools.config")
local executable = require("flutter-tools.executable")

local api = vim.api
local jobstart = vim.fn.jobstart
local jobstop = vim.fn.jobstop

local M = {}

local state = {
  job_id = nil
}

local function device_conflict(line)
  if not line then
    return false
  end
  -- match the error string returned if multiple devices are matched
  return line:match("More than one device connected") ~= nil
end

---@param lines table
local function has_device_conflict(lines)
  for _, line in pairs(lines) do
    local conflict = device_conflict(line)
    if conflict then
      return conflict
    end
  end
  return false
end

local function on_run_data(err, job, data, opts)
  if err then
    ui.notify(data)
  elseif not device_conflict(data) then
    dev_log.log(job, data, opts)
  end
end

--- Parse a list of lines looking for devices
--- return the parsed list and the found devices if any
---@param result table
local function add_device_options(result)
  local edited = {}
  local win_devices = {}
  local highlights = {}
  for index, line in pairs(result.data) do
    local device = devices.parse(line)
    if device then
      win_devices[tostring(index)] = device
      local name = utils.display_name(device.name, device.platform)
      table.insert(edited, name)
      utils.add_device_highlights(highlights, name, index, device)
    else
      table.insert(edited, line)
    end
  end
  return edited, win_devices, highlights
end

local function on_run_exit(result)
  if has_device_conflict(result) then
    local edited, win_devices, highlights = add_device_options(result)
    ui.popup_create(
      "Flutter run: ",
      edited,
      function(buf, _)
        vim.b.devices = win_devices
        ui.add_highlights(buf, highlights)
        -- we have handled this conflict by giving the user a
        result.has_conflict = false
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

function M.run(device)
  local cfg = config.get()
  local cmd = executable.with("run")
  if M.job_id then
    return utils.echomsg("Flutter is already running!")
  end
  if device and device.id then
    cmd = cmd .. " -d " .. device.id
  end
  ui.notify {"Starting flutter project..."}
  Job:new {
    cmd = cmd,
    on_stdout = function(job, data)
      on_run_data(false, job, data, cfg.dev_log)
    end,
    on_stderr = function(job, data)
      on_run_data(true, job, data, cfg.dev_log)
    end,
    on_exit = function(_, result)
      on_run_exit(result)
    end
  }:start()
end

local function on_pub_get(result)
  return function(_, data, channel)
    if not channel == "stderr" and result.error then
      result.error = true
    end
    local str = table.concat(data, "")
    if data and (str and str:len() > 0) then
      table.insert(result.data, str)
    end
  end
end

local function on_pub_get_exit(result)
  ui.notify(result.data)
end

local pub_get_job = nil

function M.pub_get()
  local result = {
    error = false,
    data = {}
  }
  if not pub_get_job then
    pub_get_job =
      jobstart(
      executable.with("pub get"),
      {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = on_pub_get(result),
        on_stderr = on_pub_get(result),
        on_exit = function()
          pub_get_job = nil
          on_pub_get_exit(result)
        end
      }
    )
  end
end

local function stop_job(id)
  if id then
    jobstop(id)
  end
end

function M.quit()
  stop_job(state.log.job_id)
  state.log.job_id = nil
  -- stop_job(emulators.job)
  -- emulators.job = nil
end

function _G.__flutter_tools_close(buf)
  vim.cmd("bw " .. buf)
end

return M
