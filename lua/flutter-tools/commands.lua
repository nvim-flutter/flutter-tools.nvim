local Job = require("flutter-tools.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local devices = require("flutter-tools.devices")
local config = require("flutter-tools.config")
local executable = require("flutter-tools.executable")
local dev_log = require("flutter-tools.log")

local api = vim.api

local M = {}

local state = {
  ---@type Job
  job = nil
}

local function device_conflict(line)
  if not line then
    return false
  end
  -- match the error string returned if multiple devices are matched
  return line:match("More than one device connected") ~= nil
end

---@param lines string[]
local function has_device_conflict(lines)
  for _, line in pairs(lines) do
    local conflict = device_conflict(line)
    if conflict then
      return conflict
    end
  end
  return false
end

local function on_run_data(err, opts)
  return function(_, data)
    if err then
      ui.notify({data})
    end
    if not device_conflict(data) then
      dev_log.log(data, opts)
    end
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

local function shutdown()
  if state.job then
    state.job:close()
    state.job = nil
  end
  devices.close_emulator()
end

function M.run(device)
  local cfg = config.get()
  local cmd = executable.with("run")
  if state.job then
    return utils.echomsg("Flutter is already running!")
  end
  if device and device.id then
    cmd = cmd .. " -d " .. device.id
  end
  ui.notify {"Starting flutter project..."}
  state.job =
    Job:new {
    cmd = cmd,
    on_stdout = on_run_data(false, cfg.dev_log),
    on_stderr = on_run_data(true, cfg.dev_log),
    on_exit = function(_, result)
      on_run_exit(result)
      shutdown()
    end
  }:start()
end

local function on_pub_get(_, result)
  ui.notify(result)
end

---@type Job
local pub_get_job = nil

function M.pub_get()
  if not pub_get_job then
    pub_get_job =
      Job:new {
      cmd = executable.with("pub get"),
      on_exit = function(err, result)
        on_pub_get(err, result)
        pub_get_job = nil
      end
    }:sync()
  end
end

---@param cmd string
---@param quiet boolean
local function send(cmd, quiet)
  if state.job then
    state.job:send(cmd)
  elseif not quiet then
    utils.echomsg [[Sorry! Flutter is not running]]
  end
end

---@param quiet boolean
function M.reload(quiet)
  send("r", quiet)
end

---@param quiet boolean
function M.restart(quiet)
  if not quiet then
    ui.notify({"Restarting..."}, 1500)
  end
  send("R", quiet)
end

---@param quiet boolean
function M.quit(quiet)
  if not quiet then
    ui.notify({"Closing flutter application..."}, 1500)
  end
  send("q", quiet)
  shutdown()
end

---@param quiet boolean
function M.visual_debug(quiet)
  send("p", quiet)
end

function _G.__flutter_tools_close(buf)
  vim.api.nvim_buf_delete(buf, {force = true})
end

return M
