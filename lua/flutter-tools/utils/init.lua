local M = {}
local fn = vim.fn
local api = vim.api

local lazy = require("flutter-tools.lazy")
local path = lazy.require("flutter-tools.utils.path") ---@module "flutter-tools.utils.path"

--- if every item in a table is an empty value return true
function M.list_is_empty(tbl)
  if not tbl then return true end
  return table.concat(tbl) == ""
end

function M.buf_valid(bufnr, name)
  local target = bufnr or name
  if not target then return false end
  if bufnr then return api.nvim_buf_is_loaded(bufnr) end
  return vim.fn.bufexists(target) > 0 and vim.fn.buflisted(target) > 0
end

local colorscheme_group = api.nvim_create_augroup("FlutterToolsColorscheme", { clear = true })
---Add a highlight group and an accompanying autocommand to refresh it
---if the colorscheme changes
---@param name string
---@param opts table
function M.highlight(name, opts)
  local function hl() api.nvim_set_hl(0, name, opts) end
  hl()
  api.nvim_create_autocmd("ColorScheme", { callback = hl, group = colorscheme_group })
end

---@generic T, S
---@param accumulator S
---@param callback fun(accumulator: S, item: T, index: number|string): S
---@param list T[]
---@return S
function M.fold(callback, list, accumulator)
  for k, v in ipairs(list) do
    accumulator = callback(accumulator, v, k)
  end
  return accumulator
end

---Find an item in a list based on a compare function
---@generic T
---@param compare fun(item: T): boolean
---@param list `T`
---@return `T`?
function M.find(list, compare)
  for _, item in ipairs(list) do
    if compare(item) then return item end
  end
end

---Merge two table but maintain metatables
---Priority is given to the second table
--- FIXME: this does not copy metatables
---@param t1 table
---@param t2 table
---@param skip string[]?
---@return table
function M.merge(t1, t2, skip)
  for k, v in pairs(t2) do
    if not skip or not vim.tbl_contains(skip, k) then
      if (type(v) == "table") and (type(t1[k] or false) == "table") then
        M.merge(t1[k], t2[k])
      else
        t1[k] = v
      end
    end
  end
  return t1
end

function M.remove_newlines(str)
  if not str or type(str) ~= "string" then return str end
  return str:gsub("[\n\r]", "")
end

function M.executable(bin) return fn.executable(bin) > 0 end

---Get the attribute value of a specified highlight
---@param name string
---@param attribute string
---@return string?
function M.get_hl(name, attribute)
  if api.nvim_get_hl then
    local hl = api.nvim_get_hl(0, { name = name })
    return hl[attribute]
  else
    local ok, hl = pcall(api.nvim_get_hl_by_name, name, true)
    if not ok then return end
    hl.foreground = hl.foreground and "#" .. bit.tohex(hl.foreground, 6)
    hl.background = hl.background and "#" .. bit.tohex(hl.background, 6)
    local attr = ({ bg = "background", fg = "foreground" })[attribute] or attribute
    return hl[attr]
  end
end

function M.open_command()
  if path.is_mac then return "open" end
  if path.is_linux then return "xdg-open" end
  if path.is_windows then return "explorer" end
  return nil, nil
end

---@param lines string[]
---@return string
function M.join(lines) return table.concat(lines, "\n") end

---Create an lsp handler compatible with the new handler signature
---see: https://github.com/neovim/neovim/pull/15504/
---@param func function
---@return function
function M.lsp_handler(func)
  return function(...)
    local config_or_client_id = select(4, ...)
    local is_new = type(config_or_client_id) ~= "number"
    if is_new then
      func(...)
    else
      local err = select(1, ...)
      local method = select(2, ...)
      local result = select(3, ...)
      local client_id = select(4, ...)
      local bufnr = select(5, ...)
      local config = select(6, ...)
      func(err, result, { method = method, client_id = client_id, bufnr = bufnr }, config)
    end
  end
end

---@enum Events
M.events = {
  PROJECT_CONFIG_CHANGED = "FlutterToolsProjectConfigChanged",
  APP_STARTED = "FlutterToolsAppStarted",
  OUTLINE_CHANGED = "FlutterToolsOutlineChanged",
  LSP_ANALYSIS_COMPLETED = "FlutterToolsLspAnalysisCompleted",
}

---@generic T:table
---@param event Events
---@param opts {data: T} | nil
function M.emit_event(event, opts)
  local data = opts and opts.data
  api.nvim_exec_autocmds("User", { pattern = event, data = data })
end

-- TODO: Remove after compatibility with Neovim=0.9 is dropped
M.islist = vim.fn.has("nvim-0.10") == 1 and vim.islist or vim.tbl_islist
local flatten = function(t) return vim.iter(t):flatten():totable() end
M.flatten = vim.fn.has("nvim-0.11") == 1 and flatten or vim.tbl_flatten

return M
