local M = {}

function M.echomsg(msg, hl)
  hl = hl or "Title"
  vim.cmd(string.format([[echomsg "%s"]], msg))
end

function M.autocommands_create(definitions)
  for group_name, definition in pairs(definitions) do
    vim.cmd("augroup " .. group_name)
    vim.cmd("autocmd!")
    for _, def in pairs(definition) do
      local command = table.concat(vim.tbl_flatten {"autocmd", def}, " ")
      vim.cmd(command)
    end
    vim.cmd("augroup END")
  end
end

---@param name string
---@return string
function M.display_name(name, platform)
  local symbol = " • "
  local result = symbol .. name .. symbol .. platform
  return result
end

function M.add_device_highlights(highlights, line, lnum, device)
  vim.list_extend(
    highlights,
    M.get_highlights(
      line,
      lnum,
      {
        word = device.name,
        highlight = "Type"
      },
      {
        word = device.platform,
        highlight = "Comment"
      }
    )
  )
end

function M.get_highlights(line, lnum, ...)
  local highlights = {}
  for i = 1, select("#", ...) do
    local item = select(i, ...)
    local s, e = line:find(item.word)
    table.insert(
      highlights,
      {
        highlight = item.highlight,
        column_start = s,
        column_end = e + 1,
        number = lnum - 1
      }
    )
  end
  return highlights
end

function M.command(name, rhs)
  vim.cmd("command! " .. name .. " " .. rhs)
end

return M
