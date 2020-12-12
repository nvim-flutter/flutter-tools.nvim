local ui = require "flutter-tools/ui"

local api = vim.api
local jobstart = vim.fn.jobstart

local M = {}
local DEV_LOG_FILE_NAME = "__FLUTTER_DEV_LOG__"

local function append(devices)
  return function(_, data, _)
    for _, item in pairs(data) do
      if item and item ~= "" then
        table.insert(devices, item)
      end
    end
  end
end

local function close(title, result)
  return function(_, _, _)
    ui.popup_create(title, result)
  end
end

local function handle_error(_, data, _)
  print(vim.inspect(data))
end

function M.get_devices()
  local devices = {}
  jobstart(
    "flutter devices",
    {
      on_stdout = append(devices),
      on_exit = close("Fluter devices", devices),
      on_stderr = handle_error
    }
  )
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
            "<CR>",
            [[:lua __flutter_tools_select_device()<CR>]],
            {silent = true, noremap = true}
          )
        end
      )
    end
  end
end

local function dev_log_open()
  return vim.fn.bufexists(DEV_LOG_FILE_NAME) > 0
end

local function dev_log_create()
  vim.cmd("vsplit " .. DEV_LOG_FILE_NAME)
  vim.cmd("setfiletype log")
  local buf = vim.fn.bufnr(DEV_LOG_FILE_NAME)
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = "nofile"
end

local function open_dev_log(_, data, _)
  local buf
  if not dev_log_open() then
    buf = dev_log_create()
  else
    buf = vim.fn.bufnr(DEV_LOG_FILE_NAME)
  end
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, -1, -1, true, data)
  vim.bo[buf].modifiable = false
end

local function handle_dev_log_err(_, err, _)
  print(vim.inspect(err))
end

local function handle_dev_log_close(_, code, _)
  print(vim.inspect(code))
end

function M.run(device)
  local cmd = "flutter run"
  if device and device.device_id then
    cmd = cmd .. "run -d " .. device.device_id
  end
  local id =
    jobstart(
    cmd,
    {
      on_stdout = open_dev_log,
      on_stderr = handle_dev_log_err,
      on_exit = handle_dev_log_close
    }
  )
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
  api.nvim_win_close(0)
end

function M.get_emulators()
  local emulators = {}
  vim.fn.jobstart(
    "flutter emulators",
    {
      on_stdout = get_device(emulators),
      on_exit = show_devices(emulators),
      on_stderr = handle_error
    }
  )
end
return M
