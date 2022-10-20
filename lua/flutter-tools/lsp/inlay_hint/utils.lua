local CLIENT_NS = vim.api.nvim_create_namespace("flutter_tools_lsp_inlay_hint")
local M = {}
function M.on_inlay_hint(err, result, ctx, config)
  if err then return require("flutter-tools.ui").notify(err) end

  vim.api.nvim_buf_clear_namespace(ctx.bufnr, CLIENT_NS, 0, -1)
  local hints = result or {}
  for _, current in ipairs(hints) do
    vim.api.nvim_buf_set_extmark(ctx.bufnr, CLIENT_NS, current.position.line, current.position.character, {
      virt_text = { { current.label, "Comment" } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })
  end
end

return M
