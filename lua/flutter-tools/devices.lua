local lazy = require("flutter-tools.lazy")
local Job = require("plenary.job") ---@module "plenary.job"
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local commands = lazy.require("flutter-tools.commands") ---@module "flutter-tools.commands"
local executable = lazy.require("flutter-tools.executable") ---@module "flutter-tools.executable"
local fmt = string.format

---@alias Device {name: string, id: string, platform: string, system: string, type: integer, cold_boot: boolean}

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
    if device then
      table.insert(devices, device)
      if type == EMULATOR and device.system and device.system == "android" then
        local cold_boot_device = vim.tbl_extend("force", {}, device, { cold_boot = true })
        cold_boot_device.name = fmt("%s (cold boot)", device.name)
        table.insert(devices, cold_boot_device)
      end
    end
  end
  return devices
end

---@param line string
---@param device_type number
---@return Device?
function M.parse(line, device_type)
  if line:find("Manufacturer") and line:find("Platform") then return end
  if line:find("crashdata") then return end
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
function M.to_selection_entries(result, device_type)
  if not result or #result < 1 then return {} end
  if not device_type then device_type = DEVICE end
  local devices = get_devices(result, device_type)
  if #devices == 0 then vim.tbl_map(function(item) return { text = item } end, result) end
  return vim.tbl_map(function(device)
    local has_platform = device.platform and device.platform ~= ""
    return {
      text = fmt(" %s %s ", device.name, has_platform and " • " .. device.platform or " "),
      type = ui.entry_type.DEVICE,
      data = device,
    }
  end, devices)
end

-----------------------------------------------------------------------------//
-- Emulators
-----------------------------------------------------------------------------//

---@param job Job
local function handle_launch(job) ui.notify(utils.join(job:result())) end

function M.close_emulator()
  if M.emulator_job then M.emulator_job:shutdown() end
end

---@param emulator table
function M.launch_emulator(emulator)
  if not emulator then return end
  executable.flutter(function(cmd)
    args = { "emulator", "--launch", emulator.id }
    if emulator.cold_boot then table.insert(args, "--cold") end
    M.emulator_job = Job:new({ command = cmd, args = args })
    M.emulator_job:after_success(vim.schedule_wrap(handle_launch))
    M.emulator_job:start()
  end)
end

---@param result string[]
local function show_emulators(result)
  local lines = M.to_selection_entries(result, EMULATOR)
  if #lines > 0 then
    ui.select({
      title = "Flutter emulators",
      lines = lines,
      on_select = function(emulator) M.launch_emulator(emulator) end,
    })
  end
end

function M.list_emulators()
  executable.flutter(function(cmd)
    local job = Job:new({ command = cmd, args = { "emulators" } })
    job:after_success(vim.schedule_wrap(function(j) show_emulators(j:result()) end))
    job:after_failure(
      vim.schedule_wrap(
        function(j) return ui.notify(utils.join(j:stderr_result()), ui.ERROR, { timeout = 5000 }) end
      )
    )
    job:start()
  end)
end

-----------------------------------------------------------------------------//
-- Devices
-----------------------------------------------------------------------------//
---@param job Job
local function show_devices(job)
  local lines = M.to_selection_entries(job:result(), DEVICE)
  if #lines > 0 then
    ui.select({
      title = "Flutter devices",
      lines = lines,
      on_select = function(device) commands.run({ device = device }) end,
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
