local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local M = {}
local api = vim.api
local outline_filename = "__FLUTTER_OUTLINE__"
M.buf = nil
local bottom_corner = "└"
local middle_corner = "├"
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

local function parse_outline(result, node, prefix, marker)
  if not node then
    return
  end
  local element = node.element or {}
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
  local lnum = ""
  if element.range then
    lnum = lnum .. ":" .. element.range.start.line
  end
  local icon = icons[element.kind]
  local display_str = {prefix, marker, icon, text, lnum}
  local column_start = #prefix + #marker + #icon
  table.insert(
    result,
    {
      hl = {
        highlight = "Title",
        column_start = column_start,
        column_end = column_start + #text
      },
      name = element.name,
      text = table.concat(display_str, " ")
    }
  )
  local children = node.children
  if not children or vim.tbl_isempty(children) then
    return
  end

  local child_prefix = prefix .. " "
  for i, child in pairs(children) do
    local child_marker = #children == i and bottom_corner or middle_corner
    parse_outline(result, child, child_prefix, child_marker)
  end
end

function M.document_outline(options)
  return function(_, _, data, _)
    local outline = data.outline or {}
    local result = {}
    for _, item in pairs(outline.children) do
      parse_outline(result, item, "", "")
    end
    local lines = {}
    local highlights = {}
    for index, item in pairs(result) do
      table.insert(
        highlights,
        vim.tbl_extend("force", item.hl, {number = index - 1})
      )
      table.insert(lines, item.text)
    end
    if not utils.buf_valid(M.buf, outline_filename) then
      ui.open_split(
        {
          open_cmd = options.open_cmd,
          filetype = "Flutter Outline",
          filename = outline_filename
        },
        function(buf, win)
          vim.wo[win].number = false
          vim.wo[win].relativenumber = false
          vim.wo[win].wrap = false
          vim.bo[buf].buflisted = false
          vim.bo[buf].bufhidden = "wipe"
          vim.bo[buf].buftype = "nofile"
          M.buf = buf
          api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
          ui.add_highlights(M.buf, highlights)
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
