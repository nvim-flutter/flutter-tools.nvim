local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")

local api = vim.api

local M = {
  --@type number
  buf = nil,
  --@type number
  win = nil,
}

M.filename = "__FLUTTER_DEV_LOG__"

--- check if the buffer exists if does and we
--- lost track of it's buffer number re-assign it
local function exists()
  local is_valid = utils.buf_valid(M.buf, M.filename)
  if is_valid and not M.buf then
    M.buf = vim.fn.bufnr(M.filename)
  end
  return is_valid
end

local function close_dev_log()
  M.buf = nil
  M.win = nil
end

local function create(config)
  local opts = {
    filename = M.filename,
    filetype = "log",
    open_cmd = config.open_cmd,
  }
  ui.open_split(opts, function(buf, win)
    if not buf then
      utils.notify("Failed to open the dev log as the buffer could not be found", utils.L.ERROR)
      return
    end
    M.buf = buf
    M.win = win
    utils.augroup("FlutterToolsBuffer" .. buf, {
      {
        events = { "BufWipeout" },
        targets = { "<buffer>" },
        command = close_dev_log,
      },
    })
  end)
end

function M.get_content()
  if M.buf then
    return api.nvim_buf_get_lines(M.buf, 0, -1, false)
  end
end

---Autoscroll the log buffer to the end of the output
---@param bufnr integer
---@param winnr integer
local function autoscroll(bufnr, winnr)
  for _, win in ipairs(api.nvim_list_wins()) do
    local buf = api.nvim_win_get_buf(win)
    -- TODO: fix invalid window id for auto scroll
    if buf == bufnr and api.nvim_win_is_valid(win) then
      local buf_length = api.nvim_buf_line_count(bufnr)
      -- if the dev log is focused don't scroll it as it will block the user from perusing
      if api.nvim_get_current_win() == win then
        return
      end
      local success = pcall(api.nvim_win_set_cursor, win, { buf_length, 0 })
      if not success then
        utils.notify(
          ("Failed to set cursor for log: win_id: %s, buf_id: %s"):format(win, buf),
          utils.L.ERROR
        )
      end
      break
    end
  end
end

--- Open a log showing the output from a command
--- in this case flutter run
---@param data string
---@param opts table
function M.log(data, opts)
  if not exists() then
    create(opts)
  end
  vim.bo[M.buf].modifiable = true
  api.nvim_buf_set_lines(M.buf, -1, -1, true, { data })
  autoscroll(M.buf, M.win)
  vim.bo[M.buf].modifiable = false
end

function M.__resurrect()
  local buf = api.nvim_get_current_buf()
  vim.cmd("setfiletype log")
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].buftype = "nofile"
end

function M.clear()
  if api.nvim_buf_is_valid(M.buf) then
    vim.bo[M.buf].modifiable = true
    api.nvim_buf_set_lines(M.buf, 0, -1, false, {})
    vim.bo[M.buf].modifiable = false
  end
end

return M
