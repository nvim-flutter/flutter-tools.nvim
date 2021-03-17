local Job = require("flutter-tools.job")
local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"
local executable = require "flutter-tools/executable"

local api = vim.api

local M = {
  ---@type Job
  emulator_job = nil
}

local EMULATOR = 1
local DEVICE = 2

---@param result string[]
---@param type integer
local function get_devices(result, type)
  local devices = {}
  for _, line in pairs(result) do
    local device = M.parse(line, type)
    if device then
      table.insert(devices, device)
    end
  end
  return devices
end

---@param line string
function M.parse(line, device_type)
  local parts = vim.split(line, "•")
  local is_emulator = device_type == EMULATOR
  local name_index = not is_emulator and 1 or 2
  local id_index = not is_emulator and 2 or 1
  if #parts == 4 then
    return {
      name = vim.trim(parts[name_index]),
      id = vim.trim(parts[id_index]),
      platform = vim.trim(parts[3]),
      system = vim.trim(parts[4]),
      type = device_type
    }
  end
end

--- Parse a list of lines looking for devices
--- return the parsed list and the found devices if any
---
---@param result string[]
---@param type integer
---@return string[]
---@return table
---@return table
function M.extract_device_props(result, type)
  type = type or DEVICE
  local lines = {}
  local highlights = {}
  local devices = get_devices(result, type)
  if #devices > 0 then
    for lnum, item in pairs(devices) do
      local name = utils.display_name(item.name, item.platform)
      utils.add_device_highlights(highlights, name, lnum, item)
      table.insert(lines, name)
    end
  else
    for _, item in pairs(result) do
      table.insert(lines, item)
    end
  end
  return lines, devices, highlights
end

local function setup_window(devices, highlights)
  return function(buf, _)
    ui.add_highlights(buf, highlights)
    if #devices > 0 then
      api.nvim_buf_set_var(buf, "devices", devices)
    end
    api.nvim_buf_set_keymap(
      buf,
      "n",
      "<CR>",
      ":lua __flutter_tools_select_device()<CR>",
      {silent = true, noremap = true}
    )
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
    if device.type == EMULATOR then
      M.launch_emulator(device)
    else
      require("flutter-tools.commands").run(device)
    end
  end
  api.nvim_win_close(0, true)
end
-----------------------------------------------------------------------------//
-- Emulators
-----------------------------------------------------------------------------//

---@param result string[]
local function handle_launch(err, result)
  if err then
    ui.notify(result)
  end
end

function M.close_emulator()
  if M.emulator_job then
    M.emulator_job:close()
  end
end

---@param emulator table
function M.launch_emulator(emulator)
  if not emulator then
    return
  end
  M.emulator_job =
    Job:new {
    cmd = executable.with("emulators --launch " .. emulator.id),
    on_exit = handle_launch
  }:sync()
end

---@param err boolean
---@param result string[]
local function show_emulators(err, result)
  if err then
    return utils.echomsg(result)
  end
  local lines, emulators, highlights = M.extract_device_props(result, EMULATOR)
  if #lines > 0 then
    ui.popup_create("Flutter emulators", lines, setup_window(emulators, highlights))
  end
end

function M.list_emulators()
  Job:new {
    cmd = executable.with("emulators"),
    on_exit = show_emulators
  }:sync()
end

-----------------------------------------------------------------------------//
-- Devices
-----------------------------------------------------------------------------//
---@param err boolean
---@param result table list of devices
local function show_devices(err, result)
  if err then
    return utils.echomsg(result)
  end
  local lines, devices, highlights = M.extract_device_props(result, DEVICE)
  if #lines > 0 then
    ui.popup_create("Flutter devices", lines, setup_window(devices, highlights))
  end
end

function M.list_devices()
  Job:new {
    cmd = executable.with("devices"),
    on_exit = show_devices,
    on_stderr = function(result)
      if result then
        utils.echomsg(result)
      end
    end
  }:sync()
end

return M
