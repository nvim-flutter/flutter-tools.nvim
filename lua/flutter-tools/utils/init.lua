local M = {}
local fn = vim.fn
local api = vim.api
local fmt = string.format

function M.echomsg(msg, hl)
  hl = hl or "Title"
  local prefix = "[Flutter-tools]: "
  if type(msg) == "string" then
    msg = { { prefix .. msg, hl } }
  elseif vim.tbl_islist(msg) then
    for i, value in ipairs(msg) do
      if #msg[i] == 2 then
        msg[i][1] = prefix .. value[1]
      end
    end
  else
    return
  end
  api.nvim_echo(msg, true, {})
end

---@param name string
---@return string
function M.display_name(name, platform)
  if not name then
    return ""
  end
  local symbol = "•"
  return symbol
    .. " "
    .. name
    .. (platform and platform ~= "" and (" " .. symbol .. " ") .. platform or "")
end

---Create a neovim command
---@param name string
---@param rhs string
---@param modifiers string[]
function M.command(name, rhs, modifiers)
  modifiers = modifiers or {}
  local nargs = modifiers and modifiers.nargs or 0
  vim.cmd(fmt("command! -nargs=%s %s %s", nargs, name, rhs))
end

--- if every item in a table is an empty value return true
function M.list_is_empty(tbl)
  if not tbl then
    return true
  end
  return table.concat(tbl) == ""
end

function M.buf_valid(bufnr, name)
  local target = bufnr or name
  if not target then
    return false
  end
  if bufnr then
    return api.nvim_buf_is_loaded(bufnr)
  end
  return vim.fn.bufexists(target) > 0 and vim.fn.buflisted(target) > 0
end

---create an autocommand
---@param name string
---@param commands table<string,string[]>[]
function M.augroup(name, commands)
  vim.cmd("augroup " .. name)
  vim.cmd("autocmd!")
  for _, c in ipairs(commands) do
    vim.cmd(
      string.format(
        "autocmd %s %s %s %s",
        table.concat(c.events, ","),
        table.concat(c.targets or {}, ","),
        table.concat(c.modifiers or {}, " "),
        c.command
      )
    )
  end
  vim.cmd("augroup END")
end

---Add a highlight group and an accompanying autocommand to refresh it
---if the colorscheme changes
---@param name string
---@param opts table
function M.highlight(name, opts)
  local hls = {}
  for k, v in pairs(opts) do
    table.insert(hls, fmt("%s=%s", k, v))
  end
  local hl_cmd = fmt("highlight! %s %s", name, table.concat(hls, " "))
  vim.cmd(hl_cmd)
  M.augroup(name .. "Refresh", {
    {
      events = { "ColorScheme" },
      targets = { "*" },
      command = hl_cmd,
    },
  })
end

function M.fold(accumulator, callback, list)
  for _, v in ipairs(list) do
    accumulator = callback(accumulator, v)
  end
  return accumulator
end

---Merge two table but maintain metatables
---Priority is given to the second table
---@param t1 table
---@param t2 table
---@return table
function M.merge(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      M.merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

function M.remove_newlines(str)
  if not str or type(str) ~= "string" then
    return str
  end
  return str:gsub("[\n\r]", "")
end

function M.executable(bin)
  return fn.executable(bin) > 0
end

---Get the attribute value of a specified highlight
---@param name string
---@param attribute string
---@return string
function M.get_hl(name, attribute)
  return fn.synIDattr(fn.hlID("Normal"), "fg")
end

function M.open_command()
  local path = require("flutter-tools.utils.path")
  if path.is_mac then
    return "open"
  end
  if path.is_linux then
    return "xdg-open"
  end
  if path.is_windows then
    return "explorer"
  end
  return nil, nil
end

return M
