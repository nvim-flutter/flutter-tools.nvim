local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local M = {}
local api = vim.api
local outline_filename = "Flutter outline"
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
  ENUM_CONSTANT = "\u{f02b}",
  DEFAULT = "\u{e612}"
}

setmetatable(
  icons,
  {
    __index = function(_, _)
      return icons.default
    end
  }
)

local hl_prefix = "FlutterToolsOutline"

local icon_highlights = {
  [icons.TOP_LEVEL_VARIABLE] = {
    name = hl_prefix .. "TopLevelVar",
    link = "Identifier"
  },
  [icons.CLASS] = {name = hl_prefix .. "Class", link = "Type"},
  [icons.FIELD] = {name = hl_prefix .. "Field", link = "Identifier"},
  [icons.CONSTRUCTOR] = {
    name = hl_prefix .. "Constructor",
    link = "Identifier"
  },
  [icons.CONSTRUCTOR_INVOCATION] = {
    name = hl_prefix .. "ConstructorInvocation",
    link = "Special"
  },
  [icons.FUNCTION] = {name = hl_prefix .. "Function", link = "Function"},
  [icons.METHOD] = {name = hl_prefix .. "Method", link = "Function"},
  [icons.GETTER] = {name = hl_prefix .. "Getter", link = "Function"},
  [icons.ENUM] = {name = hl_prefix .. "Enum", link = "Type"},
  [icons.ENUM_CONSTANT] = {
    name = hl_prefix .. "EnumConstant",
    link = "Type"
  },
  [icons.DEFAULT] = {
    name = hl_prefix .. "Default",
    link = "Comment"
  }
}

function _G.flutter_tools_set_outline_highlights()
  for _, hl in pairs(icon_highlights) do
    vim.cmd("highlight default link " .. hl.name .. " " .. hl.link)
  end
end

vim.cmd [[augroup FlutterToolsOutline]]
vim.cmd [[au!]]
vim.cmd [[autocmd VimEnter,ColorScheme * lua flutter_tools_set_outline_highlights()]]
vim.cmd [[augroup END]]

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
  local column_start = #prefix + #marker + 1
  local column_end = column_start + #icon + 1
  table.insert(
    result,
    {
      hl = {
        {
          highlight = icon_highlights[icon].name,
          column_start = column_start,
          column_end = column_end
        },
        {
          highlight = "Comment",
          column_start = #prefix + 1,
          column_end = #prefix + #marker + 1
        }
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

local function get_display_props(items)
  local lines = {}
  local highlights = {}
  for index, item in pairs(items) do
    for _, hl in pairs(item.hl) do
      hl.number = index - 1
      table.insert(highlights, hl)
    end
    table.insert(lines, item.text)
  end
  return lines, highlights
end

local function setup_outline_window(lines, highlights)
  return function(buf, win)
    M.buf = buf
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].wrap = false
    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buftype = "nofile"

    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    ui.add_highlights(M.buf, highlights)
    api.nvim_buf_set_keymap(
      buf,
      "n",
      "q",
      "<Cmd>bw!<CR>",
      {noremap = true, nowait = true, silent = true}
    )
  end
end

function M.document_outline(options)
  return function(_, _, data, _)
    local outline = data.outline or {}
    local result = {}
    for _, item in pairs(outline.children) do
      parse_outline(result, item, "", "")
    end
    local lines, highlights = get_display_props(result)
    local buf_loaded = utils.buf_valid(M.buf, outline_filename)
    if not buf_loaded then
      ui.open_split(
        {
          open_cmd = options.open_cmd,
          filetype = "flutter_outline",
          filename = outline_filename
        },
        setup_outline_window(lines, highlights)
      )
    else
      local b = M.buf or vim.fn.bufnr(outline_filename)
      vim.bo[b].modifiable = true
      api.nvim_buf_set_lines(b, 0, -1, false, lines)
      ui.add_highlights(M.buf, highlights)
      vim.bo[b].modifiable = false
    end
  end
end

return M
