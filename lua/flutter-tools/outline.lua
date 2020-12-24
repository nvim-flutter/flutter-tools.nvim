local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local M = {}
local api = vim.api
local outline_filename = "Flutter outline"
local outline_filetype = "flutterToolsOutline"

-----------------------------------------------------------------------------//
-- Icons
-----------------------------------------------------------------------------//

local markers = {
  bottom = "└",
  middle = "├",
  vertical = "│"
}

local icons = {
  TOP_LEVEL_VARIABLE = "\u{f435}",
  CLASS = "\u{f0e8}",
  FIELD = "\u{f93d}",
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

-----------------------------------------------------------------------------//
-- State
-----------------------------------------------------------------------------//
M.buf = nil
M.outlines = {}
M.options = {}

setmetatable(
  M,
  {
    __index = function(_, k)
      --- if the buffer of the outline file is nil but it *might* exist
      --- we default to also checking if any file with a similar name exists
      -- if so we return it's buffer number
      if k == "buf" then
        local buf = vim.fn.bufnr(outline_filename)
        return buf >= 0 and buf or nil
      end
      return nil
    end
  }
)

local function highlight_item(name, value, group)
  vim.cmd(string.format([[syntax match %s /%s/]], name, value))
  vim.cmd("highlight default link " .. name .. " " .. group)
end

local function set_outline_highlights()
  for key, value in pairs(markers) do
    highlight_item(hl_prefix .. key, value, "NonText")
  end
  for icon, hl in pairs(icon_highlights) do
    highlight_item(hl.name, icon, hl.link)
  end
end

---@param result table
---@param node table
---@param indent string
---@param marker string
local function parse_outline(result, node, indent, marker)
  indent = indent or ""
  marker = marker or ""
  if not node then
    return
  end
  local range = node.codeRange
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
  local display_str = {prefix, icon, text, lnum}
  -- local column_start = vim.fn.strwidth(prefix) + 1
  -- local column_end = column_start + #icon + 1
  table.insert(
    result,
    {
      lnum = range.start.line + 1,
      col = range.start.character + 1,
      name = element.name,
      text = table.concat(display_str, " ")
    }
  )

  local children = node.children
  if not children or vim.tbl_isempty(children) then
    return
  end

  local parent_marker = marker == markers.middle and markers.vertical or " "
  indent = indent .. " " .. parent_marker
  for index, child in pairs(children) do
    local new_marker = index == #children and markers.bottom or markers.middle
    parse_outline(result, child, indent, new_marker)
  end
end

local function get_display_props(items)
  local lines = {}
  local highlights = {}
  for index, item in pairs(items) do
    if item.hl then
      for _, hl in pairs(item.hl) do
        hl.number = index - 1
        table.insert(highlights, hl)
      end
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
    vim.wo[win].winfixwidth = true

    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    set_outline_highlights()

    if highlights and not vim.tbl_isempty(highlights) then
      ui.add_highlights(M.buf, highlights)
    end

    api.nvim_buf_set_keymap(
      buf,
      "n",
      "q",
      "<Cmd>bw!<CR>",
      {noremap = true, nowait = true, silent = true}
    )
    vim.cmd [[autocmd! User FlutterOutlineChanged lua __flutter_tools_refresh_outline() ]]
  end
end

---@param buf integer the buf number
---@param lines table the lines to append
---@param highlights table the highlights to apply
local function replace(buf, lines, highlights)
  vim.bo[buf].modifiable = true
  local ok = pcall(api.nvim_buf_set_lines, buf, 0, -1, false, lines)
  if ok then
    vim.bo[buf].modifiable = false
    if highlights then
      ui.add_highlights(M.buf, highlights)
    end
  end
end

local function get_buf_outline()
  local buf = api.nvim_get_current_buf()
  local outline = M.outlines[vim.uri_from_bufnr(buf)]
  if not outline or vim.tbl_isempty(outline) then
    return false, nil, nil
  end
  local lines, highlights = get_display_props(outline)
  return true, lines, highlights
end

function _G.__flutter_tools_refresh_outline()
  if not utils.buf_valid(M.buf) then
    return
  end
  local ok, lines, highlights = get_buf_outline()
  if ok then
    replace(M.buf, lines, highlights)
  end
end

function M.open(options)
  return function()
    options = options or {}
    local ok, lines, highlights = get_buf_outline()
    if not ok then
      return utils.echomsg [[Sorry! There is no outline for this file]]
    end
    local buf_loaded = utils.buf_valid(M.buf)
    if not buf_loaded and not vim.tbl_isempty(lines) then
      ui.open_split(
        {
          open_cmd = options.open_cmd,
          filetype = outline_filetype,
          filename = outline_filename
        },
        setup_outline_window(lines, highlights)
      )
    else
      replace(M.buf, lines, highlights)
    end
  end
end

function M.document_outline()
  return function(_, _, data, _)
    local outline = data.outline or {}
    local result = {}
    for _, item in pairs(outline.children) do
      parse_outline(result, item)
    end
    M.outlines[data.uri] = result
    vim.cmd [[doautocmd User FlutterOutlineChanged]]
  end
end

return M
