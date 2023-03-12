local utils = require("flutter-tools.utils")
local fmt = string.format

---@alias SelectionEntry {text: string, data: table}

local M = {
  ERROR = vim.log.levels.ERROR,
  DEBUG = vim.log.levels.DEBUG,
  INFO = vim.log.levels.INFO,
  TRACE = vim.log.levels.TRACE,
  WARN = vim.log.levels.WARN,
}

local api = vim.api
local namespace_id = api.nvim_create_namespace("flutter_tools_popups")

function M.clear_highlights(buf_id, ns_id, line_start, line_end)
  line_start = line_start or 0
  line_end = line_end or -1
  api.nvim_buf_clear_namespace(buf_id, ns_id, line_start, line_end)
end

--- @param buf_id number
--- @param lines table[]
--- @param ns_id integer?
function M.add_highlights(buf_id, lines, ns_id)
  if not buf_id then return end
  ns_id = ns_id or namespace_id
  if not lines then return end
  for _, line in ipairs(lines) do
    api.nvim_buf_add_highlight(
      buf_id,
      ns_id,
      line.highlight,
      line.line_number,
      line.column_start,
      line.column_end
    )
  end
end

--- check if there is a single non empty line
--- in the list of lines
--- @param lines table
local function invalid_lines(lines)
  for _, line in pairs(lines) do
    if line ~= "" then return false end
  end
  return true
end

---Post a message to UI so the user knows something has occurred.
---@param msg string | string[]
---@param level integer
---@param opts {timeout: number}?
M.notify = function(msg, level, opts)
  opts = opts or {}
  level = level or M.INFO
  msg = type(msg) == "table" and utils.join(msg) or msg
  if msg == "" then return end
  vim.notify(msg, level, {
    title = "Flutter tools",
    timeout = opts.timeout,
    icon = "",
  })
end

--- @param items SelectionEntry[]
--- @param on_select fun(item: SelectionEntry)
local function custom_telescope_picker(items, on_select)
  local ok, themes = pcall(require, "telescope.themes")
  if not ok then return end
  return themes.get_dropdown({
    finder = require("flutter-tools.menu").telescope_finder(vim.tbl_map(function(item)
      local data = item.data
      return {
        id = data.id,
        label = data.name,
        hint = data.platform,
        command = function()
          on_select(data)
        end,
      }
    end, items)),
  })
end

---@alias PopupOpts {title:string, lines: SelectionEntry[], on_select: fun(device: table)}
---@param opts PopupOpts
function M.select(opts)
  assert(opts ~= nil, "An options table must be passed to popup create!")
  local title, lines, on_select = opts.title, opts.lines, opts.on_select
  if not lines or #lines < 1 or invalid_lines(lines) then return end

  vim.ui.select(lines, {
    prompt = title,
    kind = "flutter-tools",
    format_item = function(item)
      return item.text
    end,
    telescope = custom_telescope_picker(lines, on_select),
  }, function(item)
    if not item then return end
    on_select(item.data)
  end)
end

---Create a split window
---@param opts table
---@param on_open fun(buf: integer, win: integer)
---@return nil
function M.open_win(opts, on_open)
  local open_cmd = opts.open_cmd or "botright 30vnew"
  local name = opts.filename or "__Flutter_Tools_Unknown__"
  open_cmd = fmt("%s %s", open_cmd, name)
  vim.cmd(open_cmd)
  vim.cmd(fmt("setfiletype %s", opts.filetype))

  local win = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = "nofile"
  if on_open then on_open(buf, win) end
end

return M
