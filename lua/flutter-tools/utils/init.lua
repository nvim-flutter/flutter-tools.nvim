local M = {}
local api = vim.api

function M.echomsg(msg, hl)
  hl = hl or "Title"
  vim.cmd("echohl " .. hl)
  vim.cmd(string.format([[echomsg "%s"]], msg))
  vim.cmd("echohl clear")
end

---@param name string
---@return string
function M.display_name(name, platform)
  if not name then
    return ""
  end
  local symbol = " • "
  local result = symbol .. name .. (platform and symbol .. platform or "")
  return result
end

function M.add_device_highlights(highlights, line, lnum, device)
  local locations =
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
  if locations then
    vim.list_extend(highlights, locations)
  end
end

--- escape any special characters in text
--- source: https://stackoverflow.com/a/20778724
---@param text string
local function escape_pattern(text)
  local pattern = "([" .. ("%^$().[]*+-?"):gsub("(.)", "%%%1") .. "])"
  return text:gsub(pattern, "%%%1")
end

function M.get_highlights(line, lnum, ...)
  local highlights = {}
  for i = 1, select("#", ...) do
    local item = select(i, ...)
    local s, e = line:find(escape_pattern(item.word))
    if not s or not e then
      return {}
    end
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

function M.fold(accumulator, fn, list)
  for _, v in ipairs(list) do
    accumulator = fn(accumulator, v)
  end
  return accumulator
end

return M
