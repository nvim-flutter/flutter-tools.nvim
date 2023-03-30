local ui = require("flutter-tools.ui")
local utils = require("flutter-tools.utils")

local M = {}

---@param item table
---@param uri string
---@return table
function M.get_action_params(item, uri)
  local bufnr = vim.uri_to_bufnr(uri)

  local start_pos = { line = item.start_line, character = item.start_col + 2 }
  local diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr, item.start_line)

  return {
    textDocument = { uri = uri },
    range = { start = start_pos, ["end"] = start_pos },
    context = { diagnostics = diagnostics },
    bufnr = bufnr,
  }
end

---Execute a code action
---this is copied verbatim from nvim's lsp handlers
---@param action table
---@param bufnr number
---@param on_complete function
function M.execute(action, bufnr, on_complete)
  bufnr = bufnr or 0
  on_complete = on_complete and utils.lsp_handler(on_complete) or nil
  -- textDocument/codeAction can return either Command[] or CodeAction[].
  -- If it is a CodeAction, it can have either an edit, a command or both.
  -- Edits should be executed first
  if action.edit or type(action.command) == "table" then
    if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, "utf-8") end
    if type(action.command) == "table" then
      vim.lsp.buf_request(bufnr, "workspace/executeCommand", action.command, on_complete)
    else
      on_complete()
    end
  else
    vim.lsp.buf_request(bufnr, "workspace/executeCommand", action, on_complete)
  end
end

---Open a code action window to select options from
---@param actions table[]
---@param on_select fun(buf: number, win: number)
function M.open(actions, on_select)
  if not actions or vim.tbl_isempty(actions) then return end

  local lines = vim.tbl_map(
    function(action)
      return {
        text = action.title:gsub("\r\n", "\\r\\n"):gsub("\n", "\\n") or "action",
        type = ui.entry_type.CODE_ACTION,
        data = action,
      }
    end,
    actions
  )

  ui.select({
    title = "Code actions",
    display = { winblend = 0 },
    position = { relative = "cursor", row = 1, col = 0 },
    lines = lines,
    on_select = on_select,
  })
end

return M
