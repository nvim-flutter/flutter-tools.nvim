local M = {}
local api = vim.api

function M.echomsg(msg, hl)
  hl = hl or "Title"
  vim.cmd("echohl " .. hl)
  vim.cmd(string.format([[echomsg "%s"]], msg))
  vim.cmd("echohl clear")
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

local last_char_pattern = "[^\128-\191][\128-\191]*$"

--- Replace the last item in a string by character
--- this works around the fact that string.sub operates
--- on bytes not on full ascii characters
---@param str string
---@param replacement string
function M.replace_last(str, replacement)
  return str:gsub(last_char_pattern, replacement)
end

function M.fold(accumulator, fn, list)
  for _, v in ipairs(list) do
    accumulator = fn(accumulator, v)
  end
  return accumulator
end

return M
