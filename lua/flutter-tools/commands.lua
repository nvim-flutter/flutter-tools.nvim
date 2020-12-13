local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"
local dev_log = require "flutter-tools/dev_log"

local api = vim.api
local jobstart = vim.fn.jobstart
local jobstop = vim.fn.jobstop

local M = {}

local state = {
  job_id = nil
}

-----------------------------------------------------------------------------//
-- Devices
-----------------------------------------------------------------------------//

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

---@param devices table list of devices
local function show_devices(devices)
  return function(_, _, _)
    local formatted = {}
    for _, item in pairs(devices) do
      table.insert(formatted, " • " .. item.name .. " ")
    end
    if #formatted > 0 then
      ui.popup_create(
        "Flutter devices",
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

function M.get_devices()
  local devices = {}
  vim.fn.jobstart(
    "flutter devices",
    {
      on_stdout = get_device(devices),
      on_exit = show_devices(devices),
      on_stderr = function(err, data, _)
        print("get devices err: " .. vim.inspect(err))
        print("get devices data: " .. vim.inspect(data))
      end
    }
  )
end

-----------------------------------------------------------------------------//
-- Emulators
-----------------------------------------------------------------------------//

function _G.__flutter_tools_select_emulator()
  local emulators = vim.b.emulators
  if not emulators then
    vim.cmd [[echomsg "Sorry there is no emulator on this line"]]
    return
  end
  local lnum = vim.fn.line(".")
  local emulator = emulators[lnum]
  if emulator then
    M.launch_emulator(emulator)
  end
  api.nvim_win_close(0, true)
end

---@param data table
---@param name string stdout, stderr, stdin
local function emulator_launch_handler(_, data, name)
  if name == "stdout" then
    if data then
      print("emulator launch stdout: " .. vim.inspect(data))
    end
  elseif name == "stderr" then
    print("emulator launch stdin: " .. vim.inspect(data))
  end
end

---@param emulator table
function M.launch_emulator(emulator)
  if not emulator then
    return
  end
  local _ =
    jobstart(
    "flutter emulators --launch " .. emulator.id,
    {
      on_exit = emulator_launch_handler,
      on_stderr = emulator_launch_handler,
      on_stdin = emulator_launch_handler
    }
  )
end

---@param emulators table
local function get_emulator(emulators)
  return function(_, data, _)
    for _, line in pairs(data) do
      local parts = vim.split(line, "•")
      if #parts == 4 then
        table.insert(
          emulators,
          {
            name = vim.trim(parts[1]),
            id = vim.trim(parts[2]),
            platform = vim.trim(parts[3]),
            system = vim.trim(parts[4])
          }
        )
      end
    end
  end
end

local function show_emulators(emulators)
  return function(_, _, _)
    local formatted = {}
    for _, item in pairs(emulators) do
      table.insert(formatted, " • " .. item.name .. " ")
    end
    if #formatted > 0 then
      ui.popup_create(
        "Flutter emulators",
        formatted,
        function(buf, _)
          api.nvim_buf_set_var(buf, "emulators", emulators)
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
            ":lua __flutter_tools_select_emulator()<CR>",
            {silent = true, noremap = true}
          )
        end
      )
    end
  end
end

function M.get_emulators()
  local emulators = {}
  vim.fn.jobstart(
    "flutter emulators",
    {
      on_stdout = get_emulator(emulators),
      on_exit = show_emulators(emulators),
      on_stderr = function(err, data, _)
        utils.echomsg(err)
        print("emulators err: " .. vim.inspect(err))
        print("emulators data: " .. vim.inspect(data))
      end
    }
  )
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

return M
