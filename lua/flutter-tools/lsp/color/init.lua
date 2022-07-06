local M = {}

function M.document_color()
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
  }

  local clients = vim.lsp.get_active_clients({ name = "dartls" })
  for _, client in ipairs(clients) do
    if client.server_capabilities.colorProvider then
      client.request("textDocument/documentColor", params, nil, 0)
    end
  end
end

M.on_document_color = require("flutter-tools.lsp.color.utils").on_document_color

return M
