local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local M = {}
local api = vim.api
local outline_filename = "__FLUTTER_OUTLINE__"
M.buf = nil

local icons = {
  TOP_LEVEL_VARIABLE = "\u{f435}",
  CLASS = "\u{f0e8}",
  FIELD = "\u{f93}",
  CONSTRUCTOR = "\u{e624}",
  CONSTRUCTOR_INVOCATION = "\u{fc2a}",
  FUNCTION = "\u{0192}",
  METHOD = "\u{f6a6}",
  GETTER = "\u{f9f}",
  ENUM = "\u{f779}",
  ENUM_CONSTANT = "\u{f02b}"
}

setmetatable(
  icons,
  {
    __index = function(_, _)
      return "\u{e612}"
    end
  }
)

local function parse_outline(result, node, prefix)
  if not node then
    return
  end
  local element = node.element or {}
  local display_str = {}
  local text = element.name
  if element.returnType then
    text = text .. element.returnType
  end
  if element.typeParameters then
    text = text .. element.typeParameters
  end
  if element.parameters then
    text = text .. element.parameters
  end
  if element.range then
    text = text .. ":" .. element.range.start.line
  end
  table.insert(display_str, prefix)
  table.insert(display_str, icons[element.kind])
  table.insert(display_str, text)
  table.insert(
    result,
    {
      name = element.name,
      text = table.concat(display_str, " ")
    }
  )
  if not node.children or vim.tbl_isempty(node.children) then
    return
  end

  prefix = prefix .. " "
  for _, child in pairs(node.children) do
    parse_outline(result, child, prefix)
  end
end

function M.document_outline(options)
  return function(_, _, data, _)
    local outline = data.outline or {}
    local result = {}
    for _, item in pairs(outline.children) do
      parse_outline(result, item, "")
    end
    local lines = {}
    for _, item in pairs(result) do
      table.insert(lines, item.text)
    end
    if not utils.buf_valid(M.buf, outline_filename) then
      ui.open_split(
        {
          open_cmd = options.open_cmd,
          filetype = "flutter_outline",
          filename = outline_filename
        },
        function(buf, win)
          vim.wo[win].number = false
          vim.wo[win].relativenumber = false
          vim.wo[win].wrap = false
          M.buf = buf
          api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
        end
      )
    else
      local b = M.buf or vim.fn.bufnr(outline_filename)
      vim.bo[b].modifiable = true
      api.nvim_buf_set_lines(b, -1, -1, true, lines)
      vim.bo[b].modifiable = false
    end
  end
end

return M
