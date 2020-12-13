local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local api = vim.api
local jobstart = vim.fn.jobstart

local M = {}
-----------------------------------------------------------------------------//
-- Emulators
-----------------------------------------------------------------------------//

function _G.__flutter_tools_select_emulator()
  local emulators = vim.b.emulators
  if not emulators then
    vim.cmd [[echomsg "Sorry there is no emulator on this line"]]
    return
  end
  local lnum = vim.fn.line(".")
  local emulator = emulators[lnum]
  if emulator then
    M.launch_emulator(emulator)
  end
  api.nvim_win_close(0, true)
end

---@param data table
---@param name string stdout, stderr, stdin
local function emulator_launch_handler(_, data, name)
  if name == "stdout" then
    if data then
      print("emulator launch stdout: " .. vim.inspect(data))
    end
  elseif name == "stderr" then
    print("emulator launch stdin: " .. vim.inspect(data))
  end
end

---@param emulator table
function M.launch_emulator(emulator)
  if not emulator then
    return
  end
  local _ =
    jobstart(
    "flutter emulators --launch " .. emulator.id,
    {
      on_exit = emulator_launch_handler,
      on_stderr = emulator_launch_handler,
      on_stdin = emulator_launch_handler
    }
  )
end

---@param emulators table
local function get_emulator(emulators)
  return function(_, data, _)
    for _, line in pairs(data) do
      local parts = vim.split(line, "•")
      if #parts == 4 then
        table.insert(
          emulators,
          {
            name = vim.trim(parts[1]),
            id = vim.trim(parts[2]),
            platform = vim.trim(parts[3]),
            system = vim.trim(parts[4])
          }
        )
      end
    end
  end
end

---@param emulators table
local function show_emulators(emulators)
  return function(_, _, _)
    local formatted = {}
    for _, item in pairs(emulators) do
      table.insert(formatted, " • " .. item.name .. " ")
    end
    if #formatted > 0 then
      ui.popup_create(
        "Flutter emulators",
        formatted,
        function(buf, _)
          api.nvim_buf_set_var(buf, "emulators", emulators)
          api.nvim_buf_set_keymap(
            buf,
            "n",
            "<CR>",
            ":lua __flutter_tools_select_emulator()<CR>",
            {silent = true, noremap = true}
          )
        end
      )
    end
  end
end

function M.list()
  local emulators = {}
  vim.fn.jobstart(
    "flutter emulators",
    {
      on_stdout = get_emulator(emulators),
      on_exit = show_emulators(emulators),
      on_stderr = function(_, data, _)
        if data and data[1] ~= "" then
          utils.echomsg(data[1])
        end
      end
    }
  )
end

return M
