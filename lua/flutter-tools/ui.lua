local utils = require "flutter-tools/utils"

local M = {}

local api = vim.api
local namespace_id = api.nvim_create_namespace("flutter_tools_popups")

local WIN_BLEND = 5

local function format_title(title, fill, width)
  local remainder = width - 1 - string.len(title)
  local side_size = math.floor(remainder) - 1
  local side = string.rep(fill, side_size)
  return title .. side
end

---@param lines table
local function pad_lines(lines)
  local formatted = {}
  for _, line in pairs(lines) do
    table.insert(formatted, " " .. line .. " ")
  end
  return formatted
end

---@param lines table
local function calculate_width(lines)
  local max_width = math.ceil(vim.o.columns * 0.8)
  local max_length = 0
  for _, line in pairs(lines) do
    if #line > max_length then
      max_length = #line
    end
  end
  return max_length <= max_width and max_length or max_width
end

function M.clear_highlights(buf_id, ns_id, line_start, line_end)
  line_start = line_start or 0
  line_end = line_end or -1
  api.nvim_buf_clear_namespace(buf_id, ns_id, line_start, line_end)
end

--- @param buf_id number
--- @param lines table
function M.add_highlights(buf_id, lines, ns_id)
  if not buf_id then
    return
  end
  ns_id = ns_id or namespace_id
  if not lines then
    return
  end
  for _, line in ipairs(lines) do
    api.nvim_buf_add_highlight(
      buf_id,
      ns_id,
      line.highlight,
      line.number,
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
    if line ~= "" then
      return false
    end
  end
  return true
end

local border_chars = {
  double = {
    top_left = "╔",
    top_right = "╗",
    middle_left = "║",
    middle_right = "║",
    bottom_left = "╚",
    bottom_right = "╝",
    fill = "═"
  },
  curved = {
    top_left = "╭",
    top_right = "╮",
    middle_left = "│",
    middle_right = "│",
    bottom_left = "╰",
    bottom_right = "╯",
    fill = "─"
  }
}

local function border_create(title, config)
  local height = config.height
  local width = config.width
  local border = border_chars.curved
  title = format_title(title, border.fill, width)
  local top = border.top_left .. title .. border.top_right
  local content = {top}
  local padding = string.rep(" ", width - 2)
  for _ = 1, height - 1 do
    table.insert(content, border.middle_left .. padding .. border.middle_right)
  end
  local bot = border.bottom_left .. string.rep(border.fill, width - 2) .. border.bottom_right

  table.insert(content, bot)

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, content)
  local win =
    api.nvim_open_win(
    buf,
    false,
    vim.tbl_extend("force", config, {focusable = false, height = #content, width = width})
  )
  vim.wo[win].winblend = WIN_BLEND
  api.nvim_win_set_option(win, "winhighlight", "NormalFloat:Normal")

  M.add_highlights(
    buf,
    {
      {
        highlight = "Title",
        number = 0,
        column_end = #title + 3,
        column_start = 3
      }
    }
  )

  config.row = config.row + 1
  config.col = config.col + 2
  config.height = config.height - 2
  config.width = config.width - 4
  return config, buf
end

function M.notify(lines, duration)
  duration = duration or 3000
  if not lines or #lines < 1 or invalid_lines(lines) then
    return
  end
  lines = pad_lines(lines)
  local opts = {
    row = 1,
    col = vim.o.columns,
    relative = "editor",
    style = "minimal",
    width = calculate_width(lines),
    height = #lines,
    anchor = "NE",
    focusable = false
  }
  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, false, opts)
  api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.wo[win].winblend = WIN_BLEND
  vim.bo[buf].modifiable = false
  vim.fn.timer_start(
    duration,
    function()
      api.nvim_win_close(win, true)
    end
  )
end

---@param title string
---@param lines table
---@param on_create function
function M.popup_create(title, lines, on_create)
  if not lines or #lines < 1 or invalid_lines(lines) then
    return
  end
  lines = pad_lines(lines)
  local width = calculate_width(lines)
  local height = 10
  local buf = api.nvim_create_buf(false, true)
  local config, border =
    border_create(
    title,
    {
      row = (vim.o.lines - height) / 2,
      col = (vim.o.columns - width) / 2,
      relative = "editor",
      style = "minimal",
      width = width,
      height = height
    }
  )
  api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  local win = api.nvim_open_win(buf, true, config)
  vim.wo[win].winblend = WIN_BLEND
  vim.bo[buf].modifiable = false
  vim.wo[win].cursorline = true
  api.nvim_win_set_option(win, "winhighlight", "CursorLine:Visual,NormalFloat:Normal")
  api.nvim_buf_set_keymap(
    buf,
    "n",
    "<ESC>",
    ":lua __flutter_tools_close(" .. buf .. ")<CR>",
    {silent = true, noremap = true}
  )
  vim.cmd(string.format([[autocmd! WinLeave <buffer> silent! execute 'bw %d %d']], buf, border))
  if on_create then
    on_create(buf, win)
  end
end

function M.open_split(opts, on_open)
  local open_cmd = opts.open_cmd or "vnew"
  local name = opts.filename or "__Flutter_Tools_Unknown__"
  local filetype = opts.filetype
  local size = opts.win_size or math.ceil(vim.o.columns * 0.33)
  vim.cmd("botright " .. size .. open_cmd)
  vim.cmd("setfiletype " .. filetype)

  local win = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()
  local success = pcall(api.nvim_buf_set_name, buf, name)
  if not success then
    return utils.echomsg [[Sorry! a split couldn't be opened]]
  end
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = "nofile"
  if on_open then
    on_open(buf, win)
  end
end

return M
