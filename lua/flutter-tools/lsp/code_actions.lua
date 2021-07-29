local M = {}

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
function M.execute(action)
  -- textDocument/codeAction can return either Command[] or CodeAction[].
  -- If it is a CodeAction, it can have either an edit, a command or both.
  -- Edits should be executed first
  if action.edit or type(action.command) == "table" then
    if action.edit then
      util.apply_workspace_edit(action.edit)
    end
    if type(action.command) == "table" then
      buf.execute_command(action.command)
    end
  else
    buf.execute_command(action)
  end
end

---Open a code action window to select options from
---@param actions table[]
function M.create_popup(actions)
  if not actions or vim.tbl_isempty(actions) then
    return
  end

  local lines = vim.tbl_map(function(action)
    return action.title:gsub("\r\n", "\\r\\n"):gsub("\n", "\\n")
  end, actions)

  require("flutter-tools.ui").popup_create({
    title = "Code actions",
    display = { winblend = 0 },
    position = { relative = "cursor", row = 1, col = 0 },
    lines = lines,
    on_create = function(buf, win)
      -- TODO: add a text edit corresponding to each line
    end,
  })
end

return M
