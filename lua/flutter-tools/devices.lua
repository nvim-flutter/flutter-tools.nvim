local Job = require("flutter-tools.job")
local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"
local executable = require "flutter-tools/executable"

local api = vim.api

local M = {}

-----------------------------------------------------------------------------//
-- Devices
-----------------------------------------------------------------------------//

function M.parse(line)
  local parts = vim.split(line, "•")
  if #parts == 4 then
    return {
      name = vim.trim(parts[1]),
      device_id = vim.trim(parts[2]),
      platform = vim.trim(parts[3]),
      system = vim.trim(parts[4])
    }
  end
end

---@param result string[]
local function get_devices(result)
  local devices = {}
  for _, line in pairs(result) do
    local device = M.parse(line)
    if device then
      table.insert(devices, device)
    end
  end
  return devices
end

local function setup_devices_win(devices, highlights)
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

---@param result table list of devices
local function show_devices(result)
  local lines = {}
  local highlights = {}
  local devices = get_devices(result)
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
  if #lines > 0 then
    ui.popup_create("Flutter devices", lines, setup_devices_win(devices, highlights))
  end
end

function M.list()
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
