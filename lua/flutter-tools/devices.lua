local Job = require("plenary.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local executable = require("flutter-tools.executable")
local fmt = string.format

---@alias Device {name: string, id: string, platform: string, system: string, type: integer}

local M = {
  ---@type Job
  emulator_job = nil,
}

local EMULATOR = 1
local DEVICE = 2

---@param result string[]
---@param type integer
local function get_devices(result, type)
  local devices = {}
  for _, line in pairs(result) do
    local device = M.parse(line, type)
    if device then table.insert(devices, device) end
  end
  return devices
end

---@param line string
---@param device_type number
---@return Device?
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
      type = device_type,
    }
  end
end

--- Parse a list of lines looking for devices
--- return the parsed list and the found devices if any
---@param result string[]
---@param device_type integer?
---@return SelectionEntry[]
function M.extract_device_props(result, device_type)
  if not result or #result < 1 then return {} end
  if not device_type then device_type = DEVICE end
  local devices = get_devices(result, device_type)
  if #devices == 0 then vim.tbl_map(function(item)
    return { text = item }
  end, result) end
  return vim.tbl_map(function(device)
    local has_platform = device.platform and device.platform ~= ""
    return {
      text = fmt(" %s %s ", device.name, has_platform and " • " .. device.platform or " "),
      data = device,
    }
  end, devices)
end

function M.select_device(device, args)
  if not device then return ui.notify("Sorry there is no device on this line") end
  local cmd = require("flutter-tools.commands")
  if device.type == EMULATOR then
    M.launch_emulator(device)
  else
    if args then
      vim.list_extend(args, { "-d", device.id })
      cmd.run({ cli_args = args })
    else
      cmd.run({ device = device })
    end
  end
end

-----------------------------------------------------------------------------//
-- Emulators
-----------------------------------------------------------------------------//

---@param job Job
local function handle_launch(job)
  ui.notify(utils.join(job:result()))
end

function M.close_emulator()
  if M.emulator_job then M.emulator_job:shutdown() end
end

---@param emulator table
function M.launch_emulator(emulator)
  if not emulator then return end
  executable.flutter(function(cmd)
    M.emulator_job = Job:new({ command = cmd, args = { "emulators", "--launch", emulator.id } })
    M.emulator_job:after_success(vim.schedule_wrap(handle_launch))
    M.emulator_job:start()
  end)
end

---@param result string[]
local function show_emulators(result)
  local lines = M.extract_device_props(result, EMULATOR)
  if #lines > 0 then
    ui.select({
      title = "Flutter emulators",
      lines = lines,
      on_select = M.select_device,
    })
  end
end

function M.list_emulators()
  executable.flutter(function(cmd)
    local job = Job:new({ command = cmd, args = { "emulators" } })
    job:after_success(vim.schedule_wrap(function(j)
      show_emulators(j:result())
    end))
    job:after_failure(vim.schedule_wrap(function(j)
      return ui.notify(utils.join(j:stderr_result()), ui.ERROR, { timeout = 5000 })
    end))
    job:start()
  end)
end

-----------------------------------------------------------------------------//
-- Devices
-----------------------------------------------------------------------------//
---@param job Job
local function show_devices(job)
  local lines = M.extract_device_props(job:result(), DEVICE)
  if #lines > 0 then
    ui.select({
      title = "Flutter devices",
      lines = lines,
      on_select = M.select_device,
    })
  end
end

function M.list_devices()
  executable.flutter(function(cmd)
    local job = Job:new({ command = cmd, args = { "devices" } })
    job:after_success(vim.schedule_wrap(show_devices))
    job:after_failure(vim.schedule_wrap(function(j)
      local result = j:result()
      local message = not vim.tbl_isempty(result) and result or j:stderr_result()
      ui.notify(utils.join(message), ui.ERROR)
    end))
    job:start()
  end)
end

return M
