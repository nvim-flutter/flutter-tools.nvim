local M = {}

local function truncate(text, limit)
  local item = {}
  for i = 1, #text, limit do
    item[#item + 1] = text:sub(i, i + limit - 1)
  end
  return item
end

function M.shorten_lines(lines, max_width)
  max_width = max_width or 50
  local formatted = {}
  for _, item in pairs(lines) do
    local current = truncate(item, max_width - 2)
    for _, line in pairs(current) do
      table.insert(formatted, " " .. line .. " ")
    end
  end
  return formatted
end

function M.echomsg(msg, hl)
  hl = hl or "Title"
  vim.cmd(string.format([[echomsg "%s"]], msg))
end

return M
