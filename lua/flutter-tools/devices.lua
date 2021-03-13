local Job = require("flutter-tools.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local executable = require("flutter-tools.executable")

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

---@param result table
local function get_devices(result)
  local output = {devices = {}, data = {}}
  for _, value in ipairs(result) do
    local device = M.parse(value)
    if device then
      table.insert(output.devices, device)
    end
    table.insert(output.data, value)
  end
  return output
end

local function setup_devices_win(result, highlights)
  return function(buf, _)
    ui.add_highlights(buf, highlights)
    if #result.devices > 0 then
      api.nvim_buf_set_var(buf, "devices", result.devices)
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
  local output = get_devices(result)

  if #output.devices > 0 then
    for lnum, item in pairs(output.devices) do
      local name = utils.display_name(item.name, item.platform)
      utils.add_device_highlights(highlights, name, lnum, item)
      table.insert(lines, name)
    end
  else
    for _, item in pairs(output.data) do
      table.insert(lines, item)
    end
  end

  if #lines > 0 then
    vim.schedule(
      function()
        ui.popup_create("Flutter devices", lines, setup_devices_win(output, highlights))
      end
    )
  end
end

function M.list()
  Job:new {
    command = executable.flutter(),
    args = {"devices"},
    on_exit = function(j, _)
      show_devices(j:result())
    end
  }:sync(8000)
end

return M
