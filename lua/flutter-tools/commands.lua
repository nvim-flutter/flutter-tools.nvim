local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"
local devices = require "flutter-tools/devices"
local dev_log = require "flutter-tools/dev_log"

local api = vim.api
local jobstart = vim.fn.jobstart
local jobstop = vim.fn.jobstop

local M = {}

local state = {
  job_id = nil
}

local function on_flutter_run_error(result)
  return function(_, data, _)
    result.has_error = true
    for _, item in pairs(data) do
      table.insert(result.data, item)
    end
  end
end

local function on_flutter_run_data(_, opts)
  return function(job_id, data, name)
    if name == "stdout" then
      dev_log.log(job_id, data, opts)
    end
  end
end

--- Parse a list of lines looking for devices
--- return the parsed list and the found devices if any
---@param result table
local function add_device_options(result)
  local edited = {}
  local win_devices = {}
  for index, line in pairs(result.data) do
    local device = devices.parse(line)
    if device then
      win_devices[tostring(index)] = device
      table.insert(edited, utils.display_name(device.name, device.platform))
    else
      table.insert(edited, line)
    end
  end
  return edited, win_devices
end

local function on_flutter_run_exit(result)
  return function(_, _, name)
    if result.has_error then
      if #result.data <= 1 and result.data[1] == "" then
        local lines = dev_log.get_content()
        result.data = lines
      end
      local edited, win_devices = add_device_options(result)
      ui.popup_create(
        "Flutter run (" .. name .. "): ",
        edited,
        function(buf, _)
          vim.b.devices = win_devices
          -- we have handled this error by giving the user a choice
          -- of devices to select
          result.has_error = false
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
end

function _G.__flutter_tools_select_device()
  local win_devices = vim.b.devices
  if not win_devices then
    vim.cmd [[echomsg "Sorry there is no device on this line"]]
    return
  end
  local lnum = vim.fn.line(".")
  local device = win_devices[lnum] or win_devices[tostring(lnum)]
  if device then
    M.run(device)
  end
  api.nvim_win_close(0, true)
end

function M.run(device, opts)
  local cmd = "flutter run"
  if M.job_id then
    utils.echomsg("A flutter process is already running")
    return
  end
  if device then
    local id = device.id or device.device_id
    if id then
      cmd = cmd .. " -d " .. id
    end
  end
  local result = {
    has_error = false,
    data = {}
  }
  state.job_id =
    jobstart(
    cmd,
    {
      on_stdout = on_flutter_run_data(result, opts),
      on_exit = on_flutter_run_exit(result),
      on_stderr = on_flutter_run_error(result)
    }
  )
end

function M.quit()
  jobstop(state.log.job_id)
  state.log.job_id = nil
end

function _G.__flutter_tools_close(buf)
  vim.cmd("bw " .. buf)
end

return M
