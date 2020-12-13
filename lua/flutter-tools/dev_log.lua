local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local api = vim.api
local M = {}

M.buf = nil
M.win = nil
M.job_id = nil

local DEV_LOG_FILE_NAME = "__FLUTTER_DEV_LOG__"

local function exists()
  if not M.buf then
    return false
  end
  return vim.fn.bufexists(M.buf) > 0
end

local function create(open_cmd)
  local opts = {
    filename = DEV_LOG_FILE_NAME,
    open_cmd = open_cmd,
    filetype = "log"
  }
  ui.open_split(
    opts,
    function(buf, win)
      if not buf then
        utils.echomsg(
          "Failed to open the dev log as the buffer could not be found"
        )
        return
      end
      M.buf = buf
      M.win = win
      vim.cmd(
        "autocmd! BufWipeout <buffer> lua __flutter_tools_close_dev_log()"
      )
    end
  )
end

function M.get_content()
  if M.buf then
    return api.nvim_buf_get_lines(M.buf, 0, -1, false)
  end
end

local function send(cmd)
  if M.job_id then
    vim.fn.chansend(M.job_id, cmd)
  else
    vim.cmd [[Sorry couldn't find the correct ID for the command]]
  end
end

function M.open(job_id, data)
  M.job_id = job_id
  if not exists() then
    create()
  end
  vim.bo[M.buf].modifiable = true
  api.nvim_buf_set_lines(M.buf, -1, -1, true, data)
  vim.bo[M.buf].modifiable = false
end

function M.reload()
  send("r")
end

function M.restart()
  send("R")
end

function M.quit()
  send("q")
end

function M.visual_debug()
  send("p")
end

function _G.__flutter_tools_close_dev_log()
  M.buf = nil
end

return M
