local ui = require "flutter-tools/ui"

local api = vim.api
local jobstart = vim.fn.jobstart

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

---@param device table
---@return string
function M.format(device)
  return " • " .. device.name .. " "
end

local function get_device(devices)
  return function(data)
    for _, line in pairs(data) do
      local device = M.parse(line)
      if device then
        table.insert(devices, device)
      end
    end
  end
end

---@param devices table list of devices
local function show_devices(devices)
  return function(_, _, _)
    local formatted = {}
    for _, item in pairs(devices) do
      table.insert(formatted, M.format(item))
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
            ":lua __flutter_tools_select_device()<CR>",
            {silent = true, noremap = true}
          )
        end
      )
    end
  end
end

function M.list()
  local devices = {}
  jobstart(
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

return M
