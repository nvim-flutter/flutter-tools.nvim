local M = {}

local lazy = require("flutter-tools.lazy")
local lsp_utils = lazy.require("flutter-tools.lsp.utils") ---@module "flutter-tools.lsp.utils"

function M.document_color()
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
  }

  local client = lsp_utils.get_dartls_client()
  if client and client.server_capabilities.colorProvider then
    client.request("textDocument/documentColor", params, nil, 0)
  end
end

M.on_document_color = require("flutter-tools.lsp.color.utils").on_document_color

return M
