local M = {}
local api = vim.api

local function format_title(title, fill, width)
  local remainder = width - 1 - string.len(title)
  local side_size = math.floor(remainder) - 1
  local side = string.rep(fill, side_size)
  return title .. side
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
  api.nvim_open_win(
    buf,
    false,
    vim.tbl_extend(
      "force",
      config,
      {focusable = false, height = #content, width = width}
    )
  )

  config.row = config.row + 1
  config.col = config.col + 2
  config.height = config.height - 2
  config.width = config.width - 4
  return config, buf
end

function M.popup_create(title, lines, on_create)
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
  vim.bo[buf].modifiable = false
  vim.wo[win].cursorline = true
  api.nvim_win_set_option(win, "winhighlight", "CursorLine:Visual")
  vim.cmd(
    string.format(
      [[autocmd! WinLeave <buffer> execute 'bw %d %d']],
      buf,
      border
    )
  )
  if on_create then
    on_create(buf, win)
  end
end

return M
