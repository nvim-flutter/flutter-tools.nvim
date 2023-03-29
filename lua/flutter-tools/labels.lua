local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.labels"

local api = vim.api
local fmt = string.format

local M = {}

local namespace = api.nvim_create_namespace("flutter_tools_closing_labels")

local function render_labels(labels, opts)
  api.nvim_buf_clear_namespace(0, namespace, 0, -1)
  opts = opts or {}
  local highlight = opts and opts.highlight or "Comment"
  local prefix = opts and opts.prefix or "// "

  for _, item in ipairs(labels) do
    local line = item.range["end"].line
    local ok, err = pcall(api.nvim_buf_set_extmark, 0, namespace, tonumber(line), -1, {
      virt_text = { {
        prefix .. item.label,
        highlight,
      } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })
    if not ok then
      local name = api.nvim_buf_get_name(0)
      ui.notify(fmt("error drawing label for %s on line %d.\nbecause: ", name, line, err), ui.ERROR)
    end
  end
end

--- returns a function which handles rendering floating labels
function M.closing_tags(err, response, _)
  local opts = config.closing_tags
  if err or not opts.enabled then return end
  local uri = response.uri
  -- This check is meant to prevent stray events from over-writing labels that
  -- don't match the current buffer.
  if uri ~= vim.uri_from_bufnr(0) then return end
  render_labels(response.labels, opts)
end

return M
