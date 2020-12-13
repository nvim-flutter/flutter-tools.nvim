local ui = require "flutter-tools/ui"

local api = vim.api
local jobstart = vim.fn.jobstart

local M = {}

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
