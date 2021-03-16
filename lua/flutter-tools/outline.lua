local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"
local config = require "flutter-tools/config"

local api = vim.api
local fn = vim.fn
local outline_filename = "Flutter Outline"
local outline_filetype = "flutterToolsOutline"
local widget_kind = "NEW_INSTANCE"

local M =
  setmetatable(
  {},
  {
    __index = function(_, k)
      --- if the buffer of the outline file is nil but it *might* exist
      --- we default to also checking if any file with a similar name exists
      -- if so we return it's buffer number
      if k == "buf" then
        local buf = fn.bufnr(outline_filename)
        return buf >= 0 and buf or nil
      end
      return nil
    end
  }
)

-----------------------------------------------------------------------------//
-- Namespaces
-----------------------------------------------------------------------------//
local widget_outline_ns_id = api.nvim_create_namespace("flutter_tools_outline_guides")
local outline_ns_id = api.nvim_create_namespace("flutter_tools_outline_selected_item")

-----------------------------------------------------------------------------//
-- Icons
-----------------------------------------------------------------------------//

local markers = {
  bottom = "└",
  middle = "├",
  vertical = "│",
  horizontal = "─"
}

local icons =
  setmetatable(
  {
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
  },
  {
    __index = function(t, _)
      return t.DEFAULT
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
M.outlines =
  setmetatable(
  {},
  {
    __index = function()
      return {}
    end
  }
)
M.options = {}

---@param name string
---@param value string
---@param group string
local function highlight_item(name, value, group)
  vim.cmd(string.format([[syntax match %s /%s/]], name, value))
  vim.cmd("highlight default link " .. name .. " " .. group)
end

local function set_outline_highlights()
  vim.cmd("highlight default link " .. hl_prefix .. "SelectedOutlineItem Search")
  for key, value in pairs(markers) do
    highlight_item(hl_prefix .. key, value, "Whitespace")
  end
  for icon, hl in pairs(icon_highlights) do
    highlight_item(hl.name, icon, hl.link)
  end
end

---@param list table
---@param highlights table
---@param item string
---@param hl string
---@param length number
local function add_segment(list, highlights, item, hl, length, pos)
  if item and item ~= "" then
    local item_length = #item
    local new_length = item_length + length
    table.insert(
      highlights,
      {
        value = item,
        highlight = hl,
        column_start = length + 1,
        column_end = new_length + 1
      }
    )
    if pos then
      table.insert(list, pos, item)
    else
      table.insert(list, item)
    end
    length = new_length
  end
  return length
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
  local text = {}
  local icon = icons[element.kind]
  local display_str = {indent, marker, icon}

  local hl = {}
  local length = #table.concat(display_str, " ")

  --- NOTE highlights are byte indexed
  --- so use "#" operator to get the byte count
  local return_type = element.returnType and element.returnType .. " "
  length = add_segment(text, hl, return_type, "Comment", length)
  length = add_segment(text, hl, element.name, "None", length)
  length = add_segment(text, hl, element.typeParameters, "Type", length)
  length = add_segment(text, hl, element.parameters, "Bold", length)

  table.insert(display_str, table.concat(text, ""))
  local content = table.concat(display_str, " ")

  table.insert(
    result,
    {
      hl = hl,
      -- this number might be required to be 1 or 0 based
      -- based on the api call using it as row, col api functions
      -- can be (1, 0) based. It is stored as 0 based as this is the
      -- most common requirement but must be one based when manipulating
      -- the cursor
      lnum = #result,
      buf_start = #indent,
      buf_end = #content,
      start_line = range.start.line,
      start_col = range.start.character - 1,
      end_line = range["end"].line,
      end_col = range["end"].character - 1,
      name = element.name,
      text = content
    }
  )

  local children = node.children
  if not children or vim.tbl_isempty(children) then
    return
  end

  local parent_marker = marker == markers.middle and markers.vertical or " "
  indent = indent .. " " .. parent_marker
  for index, child in ipairs(children) do
    local new_marker = index == #children and markers.bottom or markers.middle
    parse_outline(result, child, indent, new_marker)
  end
end

local function get_display_props(items)
  local lines = {}
  local highlights = {}
  for _, item in ipairs(items) do
    if item.hl then
      for _, hl in ipairs(item.hl) do
        hl.number = item.lnum
        table.insert(highlights, hl)
      end
    end
    table.insert(lines, item.text)
  end
  return lines, highlights
end

local function setup_autocommands()
  utils.augroup(
    "FlutterToolsOutline",
    {
      {
        events = {"User FlutterOutlineChanged"},
        command = [[lua __flutter_tools_refresh_outline()]]
      },
      {
        events = {"CursorHold"},
        targets = {"*.dart"},
        command = [[lua __flutter_tools_set_current_item()]]
      },
      {
        events = {"BufEnter"},
        targets = {"*.dart"},
        command = [[doautocmd User FlutterOutlineChanged]]
      }
    }
  )
end

---@param lines table
---@param highlights table
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

    api.nvim_buf_set_keymap(
      buf,
      "n",
      "<CR>",
      [[<Cmd>lua __flutter_tools_select_outline_item()<CR>]],
      {noremap = true, nowait = true, silent = true}
    )
    setup_autocommands()
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

---@return boolean, table|nil, table|nil, table|nil
local function get_outline_content()
  local buf = api.nvim_get_current_buf()
  local outline = M.outlines[vim.uri_from_bufnr(buf)]
  if not outline or vim.tbl_isempty(outline) then
    return false
  end
  local lines, highlights = get_display_props(outline)
  return true, lines, highlights, outline
end

function _G.__flutter_tools_refresh_outline()
  if not utils.buf_valid(M.buf) then
    return
  end
  local ok, lines, highlights = get_outline_content()
  if ok then
    replace(M.buf, lines, highlights)
  end
end

function _G.__flutter_tools_select_outline_item()
  local line = fn.line(".")
  local uri = vim.b.outline_uri
  if not uri then
    return utils.echomsg [[Sorry! this item can't be opened]]
  end
  local outline = M.outlines[uri]
  local item = outline[line]
  if not item then
    return utils.echomsg [[Sorry! this item can't be opened]]
  end
  vim.cmd("drop " .. vim.uri_to_fname(uri))
  fn.cursor(item.start_line, item.start_col)
end

local function highlight_current_item(item)
  if not utils.buf_valid(M.buf) then
    return
  end
  ui.clear_highlights(M.buf, outline_ns_id)
  ui.add_highlights(
    M.buf,
    {
      {
        highlight = hl_prefix .. "SelectedOutlineItem",
        number = item.lnum,
        column_start = item.buf_start,
        column_end = item.buf_end + 1 -- add one for padding
      }
    },
    outline_ns_id
  )
end

local function is_outline_open()
  local is_open = false
  local wins = api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(wins) do
    if M.buf == api.nvim_win_get_buf(win) then
      is_open = true
      break
    end
  end
  return is_open
end

function _G.__flutter_tools_set_current_item()
  local curbuf = api.nvim_get_current_buf()
  if not utils.buf_valid(M.buf) or not is_outline_open() or curbuf == M.buf then
    return
  end
  local uri = vim.uri_from_bufnr(curbuf)
  local outline = M.outlines[uri]
  if vim.tbl_isempty(outline) then
    return
  end
  local cursor = api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local column = cursor[2] - 1
  local current_item
  if not lnum or not column then
    return
  end
  for _, item in ipairs(outline) do
    if
      item and not vim.tbl_isempty(item) and
        (lnum > item.start_line or (lnum == item.start_line and column >= item.start_col)) and
        (lnum < item.end_line or (lnum == item.end_line and column < item.end_col))
     then
      current_item = item
    end
  end
  if current_item then
    local item_buf = vim.uri_to_bufnr(outline.uri)
    if item_buf ~= curbuf then
      return
    end
    highlight_current_item(current_item)
    local win = fn.bufwinid(M.buf)
    -- nvim_win_set_cursor is a 1,0 based method i.e.
    -- the row should be one based and the column 0 based
    api.nvim_win_set_cursor(win, {current_item.lnum + 1, current_item.buf_start})
  end
end

function M.open()
  local cfg = config.get()
  local options = cfg.outline
  local ok, lines, highlights, outline = get_outline_content()
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
  vim.b.outline_uri = outline.uri
end

function M.document_outline(_, _, data, _)
  local outline = data.outline or {}
  local result = {}
  if not outline.children or #outline.children == 0 then
    return
  end
  for _, item in ipairs(outline.children) do
    parse_outline(result, item)
  end
  result.uri = data.uri
  M.outlines[data.uri] = result
  vim.cmd [[doautocmd User FlutterOutlineChanged]]
end

-- These offsets represent the points at which each character
-- should should be added relative to the symbol it is for
--
-- remove 1 because lua is 1 based,
-- remove another 1 because the character should appear before the first character
-- remove another 1 to add visual padding
local START_OFFSET = 3

local MIDDLE_OFFSET = 2

local END_OFFSET = 1

---find the index of the first character in a line
---@param lines string[]
---@param lnum number
---@param offset number
---@return integer
local function first_marker_index(lines, lnum, offset)
  -- the lnum passed in is 0 based from the range
  -- so this function makes it one based to correctly
  -- access the line
  local line = lines[lnum + 1]
  if not line then
    return -1
  end
  local index = line:find("%S")
  if not index then
    return -1
  end
  return index - offset
end

---get the correct indent character
---@param lnum number
---@param end_line number
---@param parent_start number
---@param indent_size number
---@param children table[]
---@return string
local function get_guide_character(lnum, end_line, parent_start, indent_size, children, lines)
  for index, child in ipairs(children) do
    -- if the child is within the parent range i.e. not at the start or the end
    local child_lnum = child.range.start.line
    if index ~= #children and index ~= 1 and lnum == child_lnum then
      local child_indent = first_marker_index(lines, child_lnum, MIDDLE_OFFSET) - parent_start
      return markers.middle .. markers.horizontal:rep(child_indent)
    end
  end
  return lnum ~= end_line and markers.vertical or
    markers.bottom .. markers.horizontal:rep(indent_size)
end

---Marshal the lsp flutter outline into a flat list of items and ranges
---@param lines string[]
---@param data table
---@param result table[]
local function collect_outlines(lines, data, result)
  if not data.children or vim.tbl_isempty(data.children) then
    return
  end
  if data.kind == widget_kind then
    -- add one to the start line number because we want each marker to start beneath the symbol
    local start_lnum = data.range.start.line + 1
    -- Don't add one to the end line number because we want each
    -- marker to end *at the level* of the symbol
    local end_lnum = data.children[#data.children].range.start.line

    local start_index = first_marker_index(lines, start_lnum, START_OFFSET)
    -- Construct a list of lists each item in this list being each line of a given
    -- outline marker indent
    local line = {}
    for lnum = start_lnum, end_lnum, 1 do
      -- TODO skip empty lines since currently extmarks
      -- cannot set where there is no existing text
      if lines[lnum + 1] ~= "" then
        local end_index = first_marker_index(lines, lnum, END_OFFSET)
        local indent_size = end_index - start_index
        indent_size = indent_size > 0 and indent_size - 1 or indent_size
        table.insert(
          line,
          {
            lnum = lnum,
            start_index = start_index,
            character = get_guide_character(
              lnum,
              end_lnum,
              start_index,
              indent_size,
              data.children,
              lines
            )
          }
        )
      end
      table.insert(result, line)
    end
  end
  for _, item in ipairs(data.children) do
    collect_outlines(lines, item, result)
  end
end

---Append a single guide to the buffer across a particular range
---@param bufnum number
---@param line table
---@param outline_config table
local function render_guide(bufnum, line, outline_config)
  for _, marker in ipairs(line) do
    local success, msg =
      pcall(
      api.nvim_buf_set_extmark,
      bufnum,
      widget_outline_ns_id,
      marker.lnum,
      marker.start_index,
      {virt_text = {{marker.character, outline_config.highlight}}, virt_text_pos = "overlay"}
    )
    if not success then
      vim.api.nvim_echo({{msg, "ErrorMsg"}}, true, {})
    end
  end
end

---Parse and render the widget outline guides
---@param bufnum number
---@param outlines table
---@param outline_config table
local function flutter_outline_guides(bufnum, outlines, outline_config)
  -- TODO: would it be more performant to do some sort of diff and patched
  -- update rather than replace the namespace each time
  api.nvim_buf_clear_namespace(bufnum, widget_outline_ns_id, 0, -1)
  for _, line in ipairs(outlines) do
    render_guide(bufnum, line, outline_config)
  end
end

function M.flutter_outline(_, _, data, _)
  local outline_config = config.get().flutter_outline
  if outline_config.enabled then
    M.flutter_outlines = data
    local outlines = {}
    local bufnum = vim.uri_to_bufnr(data.uri)
    local lines = vim.api.nvim_buf_get_lines(bufnum, 0, -1, false)
    collect_outlines(lines, data.outline, outlines)
    flutter_outline_guides(bufnum, outlines, outline_config)
  end
end

return M
