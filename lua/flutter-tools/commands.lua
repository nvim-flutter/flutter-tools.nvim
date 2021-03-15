local Job = require("flutter-tools.job")
local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")
local devices = require("flutter-tools.devices")
local dev_log = require("flutter-tools.dev_log")
local executable = require("flutter-tools.executable")
local emulators = require("flutter-tools.emulators")

local api = vim.api

local M = {}

---@param lines string[]
local function has_device_conflict(lines)
  for _, line in ipairs(lines) do
    if line then
      -- match the error string returned if multiple devices are matched
      return line:match("More than one device connected") ~= nil
    end
  end
  return false
end

---Handle any errors running flutter
---@param err string
local function handle_error(err, data)
  local msg = type(err) == "string" and err or vim.inspect(err)
  vim.schedule(
    function()
      ui.notify({"Error running flutter:", data, msg})
    end
  )
end

--- Parse a list of lines looking for devices
--- return the parsed list and the found devices if any
---@param result table
---@return string[], table[], table[]
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

--- Handle outcome of a call to flutter run
---@param result table
local function handle_exit(result)
  if has_device_conflict(result) then
    local edited, win_devices, highlights = add_device_options(result)
    vim.schedule(
      function()
        ui.popup_create(
          "Flutter run exit: ",
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
    M.run(device)
  end
  api.nvim_win_close(0, true)
end

function M.run(device)
  local config = require("flutter-tools.config").value
  local args = {"run"}
  if M.job then
    return utils.echomsg("Flutter is already running!")
  end
  if device then
    local id = device.id or device.device_id
    if id then
      table.insert(args, unpack({"-d", id}))
    end
  end
  ui.notify {"Starting flutter project..."}

  M.job =
    Job:new {
    command = executable.flutter(),
    args = args,
    on_stderr = function(err, data, _)
      handle_error(err, data)
    end,
    on_stdout = function(_, data, job)
      vim.schedule(
        function()
          dev_log.log(job, data, config.dev_log)
        end
      )
    end,
    on_exit = function(job, _)
      handle_exit(job:result())
    end
  }:start()
end

local pub_get_job = nil

function M.pub_get()
  if not pub_get_job then
    pub_get_job =
      Job:new {
      command = executable.flutter(),
      args = {"pub", "get"},
      on_stderr = function(j)
        vim.schedule(
          function()
            ui.notify(j:result())
            pub_get_job = nil
          end
        )
      end,
      on_exit = function(j)
        vim.schedule(
          function()
            ui.notify(j:result())
            pub_get_job = nil
          end
        )
      end
    }:start()
  end
end

function M.quit()
  if dev_log.job then
    dev_log.job:shutdown()
    dev_log.job = nil
  end
  if emulators.job then
    emulators.job:shutdown()
    emulators.job = nil
  end
  _G.__flutter_tools_close_dev_log()
end

function _G.__flutter_tools_close(buf)
  api.nvim_buf_delete(buf, {force = true})
end

return M
