local ui = require "flutter-tools/ui"
local dev_log = require "flutter-tools/dev_log"

local api = vim.api
local jobstart = vim.fn.jobstart
local jobstop = vim.fn.jobstop

local M = {}

local state = {
  job_id = nil
}

local function get_device(devices)
  return function(_, data, _)
    for _, line in pairs(data) do
      local parts = vim.split(line, "•")
      if #parts == 4 then
        table.insert(
          devices,
          {
            name = vim.trim(parts[1]),
            device_id = vim.trim(parts[2]),
            platform = vim.trim(parts[3]),
            system = vim.trim(parts[4])
          }
        )
      end
    end
  end
end

local function show_devices(cmd, devices)
  return function(_, _, _)
    local formatted = {}
    for _, item in pairs(devices) do
      table.insert(formatted, " • " .. item.name .. " ")
    end
    if #formatted > 0 then
      ui.popup_create(
        cmd,
        formatted,
        function(buf, _)
          api.nvim_buf_set_var(buf, "devices", devices)
          api.nvim_buf_set_keymap(
            buf,
            "n",
            "<ESC>",
            ":lua __flutter_tools_close(" .. buf .. ")<CR>",
            {silent = true, noremap = true}
          )
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

function M.run(device)
  local cmd = "flutter run"
  if device and device.device_id then
    cmd = cmd .. " -d " .. device.device_id
  end
  state.job_id =
    jobstart(
    cmd,
    {
      on_stdout = dev_log.open,
      on_stderr = dev_log.err,
      on_exit = dev_log.close
    }
  )
end

function M.quit()
  jobstop(state.log.job_id)
end

function _G.__flutter_tools_close(buf)
  vim.cmd("bw " .. buf)
end

function _G.__flutter_tools_select_device()
  local devices = vim.b.devices
  if not devices then
    vim.cmd [[echomsg "Sorry there is no device on this line"]]
    return
  end
  local lnum = vim.fn.line(".")
  local device = devices[lnum]
  if device then
    M.run(device)
  end
  api.nvim_win_close(0, true)
end

local function device_picker(cmd)
  local emulators = {}
  vim.fn.jobstart(
    cmd,
    {
      on_stdout = get_device(emulators),
      on_exit = show_devices(cmd, emulators),
      on_stderr = function(err, data, _)
        print("err: " .. vim.inspect(err))
        print("data: " .. vim.inspect(data))
      end
    }
  )
end

function M.get_emulators()
  device_picker("flutter emulators")
end

function M.get_devices()
  device_picker("flutter devices")
end

return M
