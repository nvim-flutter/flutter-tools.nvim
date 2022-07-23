local utils = require("flutter-tools.utils")
local fmt = string.format

local M = {
  ERROR = vim.log.levels.ERROR,
  DEBUG = vim.log.levels.DEBUG,
  INFO = vim.log.levels.INFO,
  TRACE = vim.log.levels.TRACE,
  WARN = vim.log.levels.WARN,
}

local api = vim.api
local fn = vim.fn
local namespace_id = api.nvim_create_namespace("flutter_tools_popups")

local WIN_BLEND = 5

local state = {
  ---@type number[] list of open windows, so we can operate on them all
  open_windows = {},
  ---@type number
  last_opened = nil,
}

local function close(buf)
  vim.api.nvim_buf_delete(buf, { force = true })
end

---Create a reverse look up to find a lines number in a buffer
---based on it's content
---@param buf integer
---@return table<string, integer>
local function create_buf_lookup(buf)
  local lnum_by_line = {}
  for lnum, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, false)) do
    lnum_by_line[fn.trim(line)] = lnum - 1
  end
  return lnum_by_line
end

---@param lines string[]
local function pad_lines(lines)
  local formatted = {}
  for _, line in pairs(lines) do
    table.insert(formatted, " " .. line .. " ")
  end
  return formatted
end

---@param lines string[]
local function calculate_width(lines)
  local max_width = math.ceil(vim.o.columns * 0.8)
  local max_length = 0
  for _, line in pairs(lines) do
    if #line > max_length then max_length = #line end
  end
  return max_length <= max_width and max_length or max_width
end

function M.clear_highlights(buf_id, ns_id, line_start, line_end)
  line_start = line_start or 0
  line_end = line_end or -1
  api.nvim_buf_clear_namespace(buf_id, ns_id, line_start, line_end)
end

function M.get_line_highlights(line, items, highlights)
  highlights = highlights or {}
  for _, item in ipairs(items) do
    local match_start, match_end = line:find(vim.pesc(item.word))
    if match_start and match_end then
      highlights[line] = highlights[line] or {}
      table.insert(highlights[line], {
        highlight = item.highlight,
        column_start = match_start,
        column_end = match_end + 1,
      })
    end
  end
  return highlights
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

---Update notification window state
---@param win integer
local function update_win_state(win)
  state.open_windows = vim.tbl_filter(function(id)
    return id ~= win
  end, state.open_windows)
  if state.last_opened == win then state.last_opened = nil end
end

---Create a popup window to notify the user of an event
---@param lines string[]
---@param duration integer
local function notify(lines, duration)
  assert(type(lines) == "table", "lines passed to notify should be a list of strings")
  duration = duration or 3000
  if not lines or #lines < 1 or invalid_lines(lines) then return end
  lines = pad_lines(lines)

  local row = vim.o.lines - #lines - vim.o.cmdheight - 2

  if state.last_opened then
    ---@type table
    local config = api.nvim_win_get_config(state.last_opened)
    if config.row[false] then
      local next_row = config.row[false] - #lines - 2 -- one for padding
      -- if the next row will be outside the window then close all open windows
      -- if there is more than one, otherwise let them start to stack again from the bottom
      if next_row <= 0 then
        if #state.open_windows > 1 then
          for _, win in ipairs(state.open_windows) do
            if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
          end
        end
      else
        row = next_row
      end
    end
  end

  local columns = vim.o.columns - vim.wo.numberwidth - 2
  local notification_width = math.ceil(columns * 0.3)
  local opts = {
    row = row,
    col = vim.o.columns - 2,
    relative = "editor",
    style = "minimal",
    width = math.min(notification_width, calculate_width(lines), 60),
    height = #lines,
    anchor = "SE",
    focusable = false,
    border = require("flutter-tools.config").get("ui").border,
  }
  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, false, opts)
  vim.bo[buf].filetype = "flutter_tools_notification"
  vim.wo[win].winhighlight = table.concat({
    "NormalFloat:FlutterNotificationNormal",
    "Normal:FlutterNotificationNormal",
    "EndOfBuffer:FlutterNotificationNormal",
    "FloatBorder:FlutterNotificationBorder",
  }, ",")
  vim.wo[win].wrap = true
  api.nvim_buf_set_lines(buf, 0, -1, true, lines)

  table.insert(state.open_windows, win)
  state.last_opened = win

  vim.wo[win].winblend = WIN_BLEND
  vim.bo[buf].modifiable = false
  fn.timer_start(duration, function()
    if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
    update_win_state(win)
  end)
end

local notifications = {
  errors = {},
}

local notification_style = require("flutter-tools.config").get("ui").notification_style
---Post a message to UI so the user knows something has occurred.
---@param lines string[]
---@param opts table?
M.notify = function(lines, opts)
  opts = opts or {}
  local source = opts.source
  local timeout = opts.timeout
  local level = opts.level or "info"
  if notification_style == "native" then
    local is_error = level == M.ERROR or level == "error"
    local previous = is_error and notifications.errors[source] or {}
    local str = table.concat(lines, "\n")
    local message = not vim.tbl_isempty(previous) and previous.message .. "\n" .. str or str

    -- FIXME: you can't replace a notification which times out since it might not be there
    -- when you go to replace it.
    local notification = vim.notify(message, level, {
      title = "Flutter tools",
      timeout = timeout,
      icon = "",
      replace = previous.notification,
      hide_from_history = previous.notification ~= nil,
    })

    if is_error and source then
      notifications.errors[source] = {
        notification = notification,
        message = message,
      }
    end
  else
    notify(lines, timeout)
  end
end

---@class PopupOpts
---@field title string
---@field lines string[]
---@field display table
---@field position table
---@field on_create fun(buf: number, win:number):nil
---@field highlights table[]

--- TODO: Ideally popup_create should include a mechanism for mapping data to a line
---@param opts PopupOpts
function M.popup_create(opts)
  assert(opts ~= nil, "An options table must be passed to popup create!")
  local title = opts.title
  local lines = opts.lines
  local on_create = opts.on_create
  local highlights = opts.highlights or {}
  local display = opts.display or { winblend = WIN_BLEND }
  local position = opts.position or {}

  if not lines or #lines < 1 or invalid_lines(lines) then return end

  lines = pad_lines(lines)
  local width = calculate_width(lines)
  local height = 10
  local buf = api.nvim_create_buf(false, true)
  lines = { title, string.rep("─", width), unpack(lines) }

  position.relative = position.relative or "editor"
  position.row = position.row or (vim.o.lines - height) / 2
  position.col = position.col or (vim.o.columns - width) / 2

  api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  local win = api.nvim_open_win(buf, true, {
    row = position.row,
    col = position.col,
    relative = position.relative,
    style = "minimal",
    width = width,
    height = height,
    border = require("flutter-tools.config").get("ui").border,
  })

  local buf_highlights = {
    { highlight = "Title", line_number = 0, column_end = #title, column_start = 0 },
    { highlight = "FloatBorder", line_number = 1, column_start = 0, column_end = -1 },
  }
  local lookup = create_buf_lookup(buf)
  for key, value in pairs(highlights) do
    local lnum = lookup[fn.trim(key)]
    if lnum then
      for _, hl in ipairs(value) do
        hl.line_number = lnum
        buf_highlights[#buf_highlights + 1] = hl
      end
    end
  end

  M.add_highlights(buf, buf_highlights)

  vim.bo.filetype = "flutter_tools_popup"
  vim.wo[win].winblend = display.winblend
  vim.bo[buf].modifiable = false
  vim.wo[win].cursorline = true
  --- Positions cursor on the third line i.e. after the title and it's underline
  api.nvim_win_set_cursor(win, { 3, 0 })
  vim.wo[win].winhighlight = table.concat({
    "CursorLine:FlutterPopupSelected",
    "NormalFloat:FlutterPopupNormal",
    "Normal:FlutterPopupNormal",
    "EndOfBuffer:FlutterPopupNormal",
    "FloatBorder:FlutterPopupBorder",
  }, ",")

  utils.map("n", "q", function()
    close(buf)
  end, {
    buffer = buf,
    nowait = true,
  })
  utils.map("n", "<ESC>", function()
    close(buf)
  end, {
    buffer = buf,
    nowait = true,
  })
  vim.cmd(string.format([[autocmd! WinLeave <buffer> silent! execute 'bw %d']], buf))
  if on_create then on_create(buf, win) end
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
