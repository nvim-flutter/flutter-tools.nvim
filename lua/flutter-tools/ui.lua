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

--- @param buf_id number
--- @param hl string
--- @param lines table
local function add_highlight(buf_id, hl, lines)
  for _, line in ipairs(lines) do
    api.nvim_buf_add_highlight(
      buf_id,
      namespace_id,
      hl,
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
  local bot =
    border.bottom_left ..
    string.rep(border.fill, width - 2) .. border.bottom_right

  table.insert(content, bot)

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, content)
  local win =
    api.nvim_open_win(
    buf,
    false,
    vim.tbl_extend(
      "force",
      config,
      {focusable = false, height = #content, width = width}
    )
  )
  vim.wo[win].winblend = WIN_BLEND
  api.nvim_win_set_option(win, "winhighlight", "NormalFloat:Normal")

  add_highlight(
    buf,
    "Title",
    {
      {number = 0, column_end = #title + 3, column_start = 3}
    }
  )

  config.row = config.row + 1
  config.col = config.col + 2
  config.height = config.height - 2
  config.width = config.width - 4
  return config, buf
end

function M.popup_create(title, lines, on_create)
  if not lines or #lines < 1 or invalid_lines(lines) then
    return
  end
  local width = 50
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
  api.nvim_win_set_option(
    win,
    "winhighlight",
    "CursorLine:Visual,NormalFloat:Normal"
  )
  api.nvim_buf_set_keymap(
    buf,
    "n",
    "<ESC>",
    ":lua __flutter_tools_close(" .. buf .. ")<CR>",
    {silent = true, noremap = true}
  )
  vim.cmd(
    string.format(
      [[autocmd! WinLeave <buffer> silent! execute 'bw %d %d']],
      buf,
      border
    )
  )
  if on_create then
    on_create(buf, win)
  end
end

function M.open_split(opts, on_open)
  local open_cmd = opts.open_cmd or "botright vnew"
  local name = opts.filename or "__Flutter_Tools_Unknown__"
  local filetype = opts.filetype
  vim.cmd(open_cmd)
  vim.cmd("setfiletype " .. filetype)

  local win = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_name(buf, name)
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = "nofile"
  if on_open then
    on_open(buf, win)
  end
end

return M
