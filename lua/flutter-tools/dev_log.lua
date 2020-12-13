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
  open_cmd = open_cmd or "botright vnew"
  vim.cmd(open_cmd)
  vim.cmd("setfiletype log")

  M.win = api.nvim_get_current_win()
  M.buf = api.nvim_get_current_buf()

  api.nvim_buf_set_name(M.buf, DEV_LOG_FILE_NAME)
  vim.bo[M.buf].swapfile = false
  vim.bo[M.buf].buftype = "nofile"
  vim.cmd("autocmd! BufWipeout <buffer> lua __flutter_tools_close_dev_log()")
end

local function send(cmd)
  if M.job_id then
    vim.fn.chansend(M.job_id, cmd)
  else
    vim.cmd [[Sorry couldn't find the correct ID for the command]]
  end
end

function M.open(job_id, data, _)
  M.job_id = job_id
  if not exists() then
    create()
  end
  vim.bo[M.buf].modifiable = true
  api.nvim_buf_set_lines(M.buf, -1, -1, true, data)
  vim.bo[M.buf].modifiable = false
end

function M.err(_, err, _)
  print("dev log error: " .. vim.inspect(err))
end

function M.close(_, data, _)
  print("closing dev log: " .. vim.inspect(data))
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
