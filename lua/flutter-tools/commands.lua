local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"
local dev_log = require "flutter-tools/dev_log"

local jobstart = vim.fn.jobstart
local jobstop = vim.fn.jobstop

local M = {}

local state = {
  job_id = nil
}

local function flutter_run_handler(result)
  return function(_, data, name)
    if name == "stderr" then
      result.has_error = true
    end
    if data then
      for _, value in pairs(data) do
        table.insert(result.data, value)
      end
    end
  end
end

local function flutter_run_exit(result)
  return function(_, _, name)
    if result.has_error then
      ui.popup_create("Flutter run (" .. name .. "): ", result.data)
    end
  end
end

function M.run(device)
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
      on_data = dev_log.open,
      on_stdout = flutter_run_handler(result),
      on_stderr = flutter_run_handler(result),
      on_exit = flutter_run_exit(result)
    }
  )
end

function M.quit()
  jobstop(state.log.job_id)
end

function _G.__flutter_tools_close(buf)
  vim.cmd("bw " .. buf)
end

return M
