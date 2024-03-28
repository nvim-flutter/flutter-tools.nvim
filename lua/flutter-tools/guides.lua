local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"

local M = {}

local api = vim.api
local fmt = string.format

local widget_kind = "NEW_INSTANCE"
local hl_group = "FlutterWidgetGuides"
local widget_outline_ns_id = api.nvim_create_namespace("flutter_tools_outline_guides")

local markers = {
  bottom = "└",
  middle = "├",
  vertical = "│",
  horizontal = "─",
}

-- These offsets represent the points at which each character
-- should should be added relative to the symbol it is for
--
-- remove 1 because lua is 1 based,
local START_OFFSET = 1

local MIDDLE_OFFSET = 2

local END_OFFSET = 1

---find the index of the first character in a line
---@param lines string[]
---@param lnum integer
---@param offset integer
---@return integer
local function first_marker_index(lines, lnum, offset)
  -- the lnum passed in is 0 based from the range
  -- so this function makes it one based to correctly
  -- access the line
  local line = lines[lnum + 1]
  if not line then return -1 end
  local index = line:find("%S")
  if not index then return -1 end
  return index - offset
end

---get the correct indent character
---@param lnum integer
---@param end_line integer
---@param parent_start integer
---@param indent_size integer
---@param children table[]
---@return string
local function get_guide_character(lnum, end_line, parent_start, indent_size, children, lines)
  for index, child in ipairs(children) do
    -- if the child is within the parent range but not at the end
    local child_lnum = child.range.start.line
    if index ~= #children and lnum == child_lnum then
      local child_indent = first_marker_index(lines, child_lnum, MIDDLE_OFFSET) - parent_start
      return markers.middle .. markers.horizontal:rep(child_indent)
    end
  end
  return lnum ~= end_line and markers.vertical
    or markers.bottom .. markers.horizontal:rep(indent_size)
end

-- Marshal the lsp flutter outline into a table of lines and characters
--   {
--     1 = {[4] = "|", [8] = "|"}
--     2 = {[4] = "|", },
--     3 = {[4] = "|", },
--     4 = {[4] = "|", },
--     5 = {[4] = "|", },
--     6 = {[4] = "|", },
--     7 = {[4] = "|", [8] = "├"},
--     8 = {[4] = "|", [8] = "├" [12] = "-"},
--     6 = {[4] = "|", [8] = "|", },
--     6 = {[4] = "|", },
--   }
---@param lines string[]
---@param data table
---@param guides table<number, table>?
---@return table<number, table>?
local function collect_guides(lines, data, guides)
  guides = guides or {}
  if not data.children or vim.tbl_isempty(data.children) then return end
  if data.kind == widget_kind then
    -- add one to the start line number because we want each marker to start beneath the symbol
    local start_lnum = data.range.start.line + 1
    -- Don't add one to the end line number because we want each
    -- marker to end *at the level* of the symbol
    local end_lnum = data.children[#data.children].range.start.line

    local start_index = first_marker_index(lines, data.range.start.line, START_OFFSET)
    for lnum = start_lnum, end_lnum, 1 do
      -- TODO: skip empty lines since currently extmarks,
      -- cannot be set where there is no existing text
      -- 2. if we get an invalid end index don't bother trying to draw guides
      local end_index = first_marker_index(lines, lnum, END_OFFSET)
      if lines[lnum + 1] ~= "" and end_index ~= -1 then
        local indent_size = end_index - start_index
        -- Don't do the work when there is no indent
        if indent_size > 0 then
          indent_size = indent_size - 1
          guides[lnum] = guides[lnum] or {}
          -- Don't do the work to get characters we already have
          -- also if the start index is out of range e.g. -1 don't add it
          if not guides[lnum][start_index] and start_index >= 0 then
            guides[lnum][start_index] =
              get_guide_character(lnum, end_lnum, start_index, indent_size, data.children, lines)
          end
        end
      end
    end
  end
  for _, item in ipairs(data.children) do
    collect_guides(lines, item, guides)
  end
  return guides
end

---Parse and render the widget outline guides
---@param bufnum number
---@param guides table<number,table>?
---@param conf table
local function render_guides(bufnum, guides, conf)
  -- TODO:
  -- would it be more performant to do some sort of diff and patched
  -- update rather than replace the namespace each time, similar to Dart Code
  api.nvim_buf_clear_namespace(bufnum, widget_outline_ns_id, 0, -1)
  if not guides then return end
  for lnum, guide in pairs(guides) do
    for start, character in pairs(guide) do
      local success, msg =
        pcall(api.nvim_buf_set_extmark, bufnum, widget_outline_ns_id, lnum, start, {
          virt_text = { { character, hl_group } },
          virt_text_pos = "overlay",
          hl_mode = "combine",
        })
      if not success and conf.debug then
        local name = api.nvim_buf_get_name(bufnum)
        ui.notify(
          fmt(
            "error drawing widget guide for %s at line %d, col %d.\nbecause: %s",
            name,
            lnum,
            start,
            msg
          ),
          ui.ERROR
        )
      end
    end
  end
end

function M.setup()
  local color = utils.get_hl("Normal", "fg")
  if color and color ~= "" then
    utils.highlight(hl_group, { foreground = color, default = true })
  end
end

local function is_buf_valid(bufnum)
  return bufnum
    and api.nvim_buf_is_valid(bufnum)
    and not vim.wo.previewwindow
    and vim.bo.buftype == ""
end

function M.widget_guides(_, data, _, _)
  local conf = config.widget_guides
  if conf.enabled then
    local bufnum = vim.uri_to_bufnr(data.uri)
    if not is_buf_valid(bufnum) then return end
    -- TODO: should this be limited to the view port using vim.fn.line('w0'|'w$')
    -- although ideally having to track what the current visible
    -- segment of a buffer is and trying to apply the extmarks in
    -- in real-time might prove difficult e.g. what autocommand do we use
    -- also will this actually be faster
    local lines = vim.api.nvim_buf_get_lines(bufnum, 0, -1, false)
    render_guides(bufnum, collect_guides(lines, data.outline), conf)
  end
end

return M
