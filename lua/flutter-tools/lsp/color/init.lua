local M = {}

function M.document_color()
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
  }
  vim.lsp.buf_request(0, "textDocument/documentColor", params)
end

M.on_document_color = require("flutter-tools.lsp.color.utils").on_document_color

return M
